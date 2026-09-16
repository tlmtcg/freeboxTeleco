import 'dart:convert';
import 'package:http/http.dart' as http;

class FreeboxOS {
  final String host;

  FreeboxOS(this.host);

  Future<dynamic> get(String path) async {
    final url = Uri.parse("http://$host$path");

    final res = await http.get(url);

    // print("GET $url");
    // print("HTTP ${res.statusCode}");
    // print("BODY ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        "GET $path : HTTP ${res.statusCode} - ${res.body}",
      );
    }

    return jsonDecode(res.body);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse("http://$host$path");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    // print("POST $url");
    // print("HTTP ${res.statusCode}");
    // print("BODY ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        "POST $path : HTTP ${res.statusCode} - ${res.body}",
      );
    }

    return jsonDecode(res.body);
  }
}
