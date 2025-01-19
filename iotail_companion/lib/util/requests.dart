import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<Map> login(String ip, String email, String password) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final url = Uri.http("$ip:8080", "login"); // URL for request
  final body = jsonEncode({
    "email": email,
    "password": password,
  }); // body for request
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "error": "Failed to login"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  Map data = {"token": tmp["token"], "userID": tmp["userID"]};
  return data; // return the response
}

Future<Map> register(String ip, Map<String, String> user) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final Uri url = Uri.http("$ip:8080", "register"); // URL for request
  final String? email = user["email"];
  final body = jsonEncode({"email": email});
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to send registration email"
    }; // return error if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> confirm_registration(String ip, Map<String, String> user) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final Uri url =
      Uri.http("$ip:8080", "confirm_registration"); // URL for request
  final body = jsonEncode(user);
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to register"
    }; // return error if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  Map data = {"token": tmp["token"], "userID": tmp["userID"]};
  return data; // return the response
}

Future<Map<String, dynamic>> getUser(
    String ip, String userID, String token) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
  final response = await http.get(url, headers: headers); // post request
  if (response.statusCode != 200) {
    throw Exception("Failed to get user");
  } // throw exception if status code is not 200
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Uint8List?> getProfilePicture(
    String ip, String userID, String token) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/profile_picture/$userID");
  final response = await http.get(url, headers: headers); // get request

  if (response.statusCode == 200) {
    return response.bodyBytes; // Get the raw image bytes
  }
  return null;
}

Future<Map<String, dynamic>> deleteProfilePicture(
    String ip, String token, String userID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  final url = Uri.http("$ip:8080", "/profile_picture/$userID");
  final response = await http.delete(url, headers: headers);
  if (response.statusCode != 200) {
    return {"message": "Failed to delete profile picture"};
  }
  Map<String, dynamic> tmp = jsonDecode(response.body);
  return tmp;
}

Future<Map> editUser(String ip, String token, String userID, Map data) async {
  final headers = {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
  var request = http.MultipartRequest("PUT", url);
  request.headers.addAll(headers);
  request.fields['userData'] = jsonEncode(data);
  request.files.add(await http.MultipartFile.fromPath(
    'profilePicture',
    data["profilePicture"],
    contentType: MediaType("image", "jpeg"),
  ));
  final response = await request.send();
  if (response.statusCode != 200) {
    return {
      "message": "Failed to edit user"
    }; // return error if status code is not 200
  }
  return {"message": "User updated"}; // return the response
}

Future<Map<String, dynamic>> recover_password(String ip, String email) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/recover"); // URL for request
  final body = jsonEncode({
    "email": email,
  }); // body for request
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to recover password"
    }; // return error if status code is not 200
  }
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> reset_password(
    String ip, String recovery_code, String email, String password) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/reset_password"); // URL for request
  final body = jsonEncode({
    "recovery_code": recovery_code,
    "email": email,
    "password": password,
  }); // body for request
  final response =
      await http.put(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to reset password"
    }; // return error if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> deleteUser(String ip, String token, String userID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
  final response = await http.delete(url, headers: headers); // delete request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to delete user"
    }; // return error if status code is not 200
  }
  return {
    "message": "User $userID deleted successfully"
  }; // return success message
}

Future<List> getStores(String ip, String token) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "stores"); // url for request
  final response = await http.get(url, headers: headers); // get request
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to get stores"); // throw exception if status code is not 200
  }
  List tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<List> getReservations(
  String ip,
  String userID,
  String token,
) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/status/$userID"); // URL for request
  final response = await http.get(url, headers: headers); // get request
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to get reservations"); // throw exception if status code is not 200
  }
  List tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> reserve(String ip, String token, Map data) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/reserve"); // URL for request
  final response = await http.post(url,
      body: jsonEncode(data), headers: headers); // post request
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to reserve"); // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> cancel_reservation(
    String ip, String token, String reservationID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/cancel/$reservationID"); // URL for request
  final response = await http.delete(url, headers: headers); // post request
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to cancel reservation"); // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}
