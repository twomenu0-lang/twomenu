import 'dart:convert';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';
import '/../utils/Constants.dart';

bool isSuccessful(int code) {
  return code >= 200 && code <= 206;
}


Future handleResponse(Response response) async {
  String body = response.body;
  if (isSuccessful(response.statusCode)) {
    return jsonDecode(body);
  } else {
    if (!await isNetworkAvailable()) {
      throw 'You are not connected to Internet';
    }
    var string = await (isJsonValid(body));
    if (string!.isNotEmpty) {
      throw string;
    } else {
      throw 'Please try again later.';
    }
  }
}

extension json on Map {
  toJson() {
    return jsonEncode(this);
  }
}

Future<String?> isJsonValid(json) async {
  try {
    var f = jsonDecode(json) as Map<String, dynamic>;
    return f[msg];
  } catch (e) {
    log(e.toString());
    return "";
  }
}