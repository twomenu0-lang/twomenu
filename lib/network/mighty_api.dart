import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import "dart:core";
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import '../utils/Common.dart';
import '/../utils/Constants.dart';
import '/../utils/QueryString.dart';
import 'package:nb_utils/nb_utils.dart';

final _sharedClient = http.Client();

class MightyAPI {
  late String url;
  String? consumerKey;
  String? consumerSecret;
  bool? isHttps;

  MightyAPI() {
    this.url = getStringAsync(APP_URL);
    this.consumerKey = getStringAsync(CONSUMER_KEY);
    this.consumerSecret = getStringAsync(CONSUMER_SECRET);

    if (this.url.startsWith("https")) {
      this.isHttps = true;
    } else {
      this.isHttps = false;
    }
  }

  String _getOAuthURL(String requestMethod, String endpoint) {
    var consumerKey = this.consumerKey;
    var consumerSecret = this.consumerSecret;
    var token = "";
    var tokenSecret = "";
    var url = this.url + endpoint;
    var containsQueryParams = url.contains("?");

    if (this.isHttps == true) {
      return url +
          (containsQueryParams == true
              ? "&consumer_key=" + this.consumerKey! + "&consumer_secret=" + this.consumerSecret!
              : "?consumer_key=" + this.consumerKey! + "&consumer_secret=" + this.consumerSecret!);
    } else {
      var rand = new Random();
      var codeUnits = new List.generate(10, (index) {
        return rand.nextInt(26) + 97;
      });
      var nonce = new String.fromCharCodes(codeUnits);
      int timestamp = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var method = requestMethod;
      var parameters = "oauth_consumer_key=" +
          consumerKey! +
          "&oauth_nonce=" +
          nonce +
          "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
          timestamp.toString() +
          "&oauth_token=" +
          token +
          "&oauth_version=1.0&";

      if (containsQueryParams == true) {
        parameters = parameters + url.split("?")[1];
      } else {
        parameters = parameters.substring(0, parameters.length - 1);
      }

      Map<dynamic, dynamic> params = QueryString.parse(parameters);
      Map<dynamic, dynamic> treeMap = new SplayTreeMap<dynamic, dynamic>();
      treeMap.addAll(params);
      String parameterString = "";
      for (var key in treeMap.keys) {
        parameterString = parameterString + Uri.encodeQueryComponent(key) + "=" + treeMap[key] + "&";
      }
      parameterString = parameterString.substring(0, parameterString.length - 1);
      var baseString = method + "&" + Uri.encodeQueryComponent(containsQueryParams == true ? url.split("?")[0] : url) + "&" + Uri.encodeQueryComponent(parameterString);
      var signingKey = consumerSecret! + "&" + tokenSecret;
      var hmacSha1 = new crypto.Hmac(crypto.sha1, utf8.encode(signingKey));
      var signature = hmacSha1.convert(utf8.encode(baseString));
      var finalSignature = base64Encode(signature.bytes);
      var requestUrl = "";
      if (containsQueryParams == true) {
        requestUrl = url.split("?")[0] + "?" + parameterString + "&oauth_signature=" + Uri.encodeQueryComponent(finalSignature);
      } else {
        requestUrl = url + "?" + parameterString + "&oauth_signature=" + Uri.encodeQueryComponent(finalSignature);
      }
      return requestUrl;
    }
  }

  Future<http.Response> postJwtAsync(String endPoint, Map data) async {
    var fullUrl = this.url + endPoint;
    log('JWT POST: $fullUrl');
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };
    try {
      var response = await _sharedClient
          .post(Uri.parse(fullUrl), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
      print('JWT Status: ${response.statusCode}');
      print('JWT Response: ${response.body}');
      return response;
    } catch (e) {
      log('JWT connection error, retrying: $e');
      final freshClient = http.Client();
      return await freshClient
          .post(Uri.parse(fullUrl), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
    }
  }

  Future<http.Response> getAsync(String endPoint, {requireToken = false}) async {
    var url = this._getOAuthURL("GET", endPoint);
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };

    if (requireToken) {
      String tok = getStringAsync(TOKEN);
      headers["Authorization"] = "Bearer $tok";
    }

    try {
      final response = await _sharedClient
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));
      log('${response.statusCode} $url');

      if (response.statusCode == 401 || response.statusCode == 403) {
        Map<String, dynamic> responseMap = json.decode(response.body);
        log(responseMap['code']);
        if (responseMap['code'] == 'jwt_auth_user_not_found' ||
            responseMap['code'] == 'jwt_auth_invalid_token') {
          setLogoutData(getContext);
        }
      }
      return response;
    } catch (e) {
      log('GET connection error, retrying: $e');
      final freshClient = http.Client();
      final response = await freshClient
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));
      log('Retry ${response.statusCode} $url');
      return response;
    }
  }

  Future<http.Response> postAsync(String endPoint, Map data, {requireToken = false}) async {
    var url = this._getOAuthURL("POST", endPoint);
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };
    if (requireToken) {
      headers["Authorization"] = "Bearer ${getStringAsync(TOKEN)}";
    }

    try {
      var response = await _sharedClient
          .post(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
      print(response.statusCode);
      print("Response" + response.body);
      return response;
    } catch (e) {
      log('POST connection error, retrying: $e');
      final freshClient = http.Client();
      return await freshClient
          .post(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
    }
  }

  Future<http.Response> putAsync(String endPoint, Map data, {requireToken = false}) async {
    var url = this._getOAuthURL("POST", endPoint);
    log(url);
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };
    if (requireToken) {
      headers["token"] = "${getStringAsync(TOKEN)}";
      headers["id"] = "${getIntAsync(USER_ID)}";
    }

    try {
      var response = await _sharedClient
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
      log(response.statusCode);
      log(jsonDecode(response.body));
      return response;
    } catch (e) {
      log('PUT connection error, retrying: $e');
      final freshClient = http.Client();
      return await freshClient
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(Duration(seconds: 30));
    }
  }

  Future<http.Response> deleteAsync(String endPoint) async {
    var url = this._getOAuthURL("DELETE", endPoint);
    log(url);
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };

    try {
      final response = await _sharedClient
          .delete(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));
      return response;
    } catch (e) {
      log('DELETE connection error, retrying: $e');
      final freshClient = http.Client();
      return await freshClient
          .delete(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));
    }
  }
}