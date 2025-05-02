import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  static Future<Map<String, dynamic>> fetchFromDatabase(String certificateID) async {
    final response = await http.get(Uri.parse(
        "http://192.168.1.1/verify_certificate.php?certificate_id=$certificateID"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Database error");
    }
  }
}
