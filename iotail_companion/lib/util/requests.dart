import 'dart:convert';
import 'package:http/http.dart' as http;

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
    throw Exception(
        "Failed to get user"); // throw exception if status code is not 200
  }
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

Future<Map> editUser(String ip, String token, String userID, Map data) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
  final response = await http.put(url,
      body: jsonEncode(data), headers: headers); // put request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to edit user"
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
