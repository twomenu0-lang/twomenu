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

// ─────────────────────────────────────────────────────────────────
// HTTP CLIENT — shared client مع keep-alive لتقليل TCP handshake
// ─────────────────────────────────────────────────────────────────
final _sharedClient = http.Client();

// ─────────────────────────────────────────────────────────────────
// TIMEOUTS
// 15s للـ request الأول — كافي على موبايل وبيمنع تجميد الـ UI
// 10s للـ retry — لو الـ request الأول فشل، مش هنستنى أكتر
// ─────────────────────────────────────────────────────────────────
const Duration _kRequestTimeout = Duration(seconds: 15);
const Duration _kRetryTimeout   = Duration(seconds: 10);

// ─────────────────────────────────────────────────────────────────
// HEADERS — base headers مع cache control للـ GET requests
// ─────────────────────────────────────────────────────────────────
Map<String, String> _baseHeaders({bool withCache = false}) {
  final headers = <String, String>{
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.connectionHeader:  'keep-alive',
  };
  if (withCache) {
    // يسمح للـ HTTP layer بـ cache الـ response لمدة دقيقتين
    headers['Cache-Control'] = 'max-age=120';
  }
  return headers;
}

class MightyAPI {
  late String url;
  String? consumerKey;
  String? consumerSecret;
  bool? isHttps;

  MightyAPI() {
    this.url           = getStringAsync(APP_URL);
    this.consumerKey   = getStringAsync(CONSUMER_KEY);
    this.consumerSecret = getStringAsync(CONSUMER_SECRET);
    this.isHttps       = this.url.startsWith("https");
  }

  // ───────────────────────────────────────────────────────────────
  // OAUTH URL BUILDER
  // ───────────────────────────────────────────────────────────────
  String _getOAuthURL(String requestMethod, String endpoint) {
    final consumerKey    = this.consumerKey;
    final consumerSecret = this.consumerSecret;
    const token          = "";
    const tokenSecret    = "";
    final url            = this.url + endpoint;
    final containsQueryParams = url.contains("?");

    if (this.isHttps == true) {
      final separator = containsQueryParams ? "&" : "?";
      return "$url${separator}consumer_key=${this.consumerKey!}&consumer_secret=${this.consumerSecret!}";
    }

    // HTTP — OAuth 1.0 signing
    final rand      = Random();
    final codeUnits = List.generate(10, (_) => rand.nextInt(26) + 97);
    final nonce     = String.fromCharCodes(codeUnits);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var parameters = "oauth_consumer_key=$consumerKey"
        "&oauth_nonce=$nonce"
        "&oauth_signature_method=HMAC-SHA1"
        "&oauth_timestamp=$timestamp"
        "&oauth_token=$token"
        "&oauth_version=1.0&";

    if (containsQueryParams) {
      parameters = parameters + url.split("?")[1];
    } else {
      parameters = parameters.substring(0, parameters.length - 1);
    }

    final params  = QueryString.parse(parameters);
    final treeMap = SplayTreeMap<dynamic, dynamic>()..addAll(params);

    String parameterString = "";
    for (var key in treeMap.keys) {
      parameterString += "${Uri.encodeQueryComponent(key)}=${treeMap[key]}&";
    }
    parameterString = parameterString.substring(0, parameterString.length - 1);

    final baseUrl   = containsQueryParams ? url.split("?")[0] : url;
    final baseString = "$requestMethod&${Uri.encodeQueryComponent(baseUrl)}&${Uri.encodeQueryComponent(parameterString)}";
    final signingKey = "$consumerSecret&$tokenSecret";
    final hmacSha1   = crypto.Hmac(crypto.sha1, utf8.encode(signingKey));
    final signature  = hmacSha1.convert(utf8.encode(baseString));
    final finalSignature = base64Encode(signature.bytes);

    if (containsQueryParams) {
      return "${url.split("?")[0]}?$parameterString&oauth_signature=${Uri.encodeQueryComponent(finalSignature)}";
    } else {
      return "$url?$parameterString&oauth_signature=${Uri.encodeQueryComponent(finalSignature)}";
    }
  }

  // ───────────────────────────────────────────────────────────────
  // JWT POST — للـ auth endpoints
  // ───────────────────────────────────────────────────────────────
  Future<http.Response> postJwtAsync(String endPoint, Map data) async {
    final fullUrl = this.url + endPoint;
    log('JWT POST: $fullUrl');
    final headers = _baseHeaders();

    try {
      final response = await _sharedClient
          .post(Uri.parse(fullUrl), body: jsonEncode(data), headers: headers)
          .timeout(_kRequestTimeout);
      log('JWT ${response.statusCode}');
      return response;
    } catch (e) {
      log('JWT retry: $e');
      return await http.Client()
          .post(Uri.parse(fullUrl), body: jsonEncode(data), headers: headers)
          .timeout(_kRetryTimeout);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // GET — مع cache headers للـ read-only endpoints
  // ───────────────────────────────────────────────────────────────
  Future<http.Response> getAsync(String endPoint, {requireToken = false}) async {
    final url     = _getOAuthURL("GET", endPoint);
    final headers = _baseHeaders(withCache: !requireToken); // cache فقط للـ public endpoints

    if (requireToken) {
      headers["Authorization"] = "Bearer ${getStringAsync(TOKEN)}";
    }

    try {
      final response = await _sharedClient
          .get(Uri.parse(url), headers: headers)
          .timeout(_kRequestTimeout);
      log('GET ${response.statusCode} $endPoint');

      // Token expired — logout تلقائي
      if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final body = json.decode(response.body) as Map<String, dynamic>;
          final code = body['code'] as String?;
          if (code == 'jwt_auth_user_not_found' || code == 'jwt_auth_invalid_token') {
            setLogoutData(getContext);
          }
        } catch (_) {}
      }

      return response;
    } catch (e) {
      log('GET retry: $e — $endPoint');
      final response = await http.Client()
          .get(Uri.parse(url), headers: headers)
          .timeout(_kRetryTimeout);
      log('GET retry ${response.statusCode}');
      return response;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // POST
  // ───────────────────────────────────────────────────────────────
  Future<http.Response> postAsync(String endPoint, Map data, {requireToken = false}) async {
    final url     = _getOAuthURL("POST", endPoint);
    final headers = _baseHeaders();

    if (requireToken) {
      headers["Authorization"] = "Bearer ${getStringAsync(TOKEN)}";
    }

    try {
      final response = await _sharedClient
          .post(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(_kRequestTimeout);
      log('POST ${response.statusCode} $endPoint');
      return response;
    } catch (e) {
      log('POST retry: $e — $endPoint');
      return await http.Client()
          .post(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(_kRetryTimeout);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // PUT
  // ───────────────────────────────────────────────────────────────
  Future<http.Response> putAsync(String endPoint, Map data, {requireToken = false}) async {
    final url     = _getOAuthURL("POST", endPoint);
    final headers = _baseHeaders();

    if (requireToken) {
      headers["token"] = getStringAsync(TOKEN);
      headers["id"]    = "${getIntAsync(USER_ID)}";
    }

    try {
      final response = await _sharedClient
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(_kRequestTimeout);
      log('PUT ${response.statusCode} $endPoint');
      return response;
    } catch (e) {
      log('PUT retry: $e — $endPoint');
      return await http.Client()
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(_kRetryTimeout);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // DELETE
  // ───────────────────────────────────────────────────────────────
  Future<http.Response> deleteAsync(String endPoint) async {
    final url     = _getOAuthURL("DELETE", endPoint);
    final headers = _baseHeaders();

    try {
      final response = await _sharedClient
          .delete(Uri.parse(url), headers: headers)
          .timeout(_kRequestTimeout);
      log('DELETE ${response.statusCode} $endPoint');
      return response;
    } catch (e) {
      log('DELETE retry: $e — $endPoint');
      return await http.Client()
          .delete(Uri.parse(url), headers: headers)
          .timeout(_kRetryTimeout);
    }
  }
}