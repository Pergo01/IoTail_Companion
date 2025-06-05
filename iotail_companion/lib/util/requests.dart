import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Send a registration email to the user.
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

/// Function to complete the registration process.
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

/// Authenticate a user with the server.
Future<Map> login(
    String ip, String email, String password, String firebaseToken) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final url = Uri.http("$ip:8080", "login"); // URL for request
  final body = jsonEncode({
    "email": email,
    "password": password,
    "firebaseToken": firebaseToken,
  }); // body for request
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "error": "Failed to login"
    }; // return error if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  Map data = {"token": tmp["token"], "userID": tmp["userID"]};
  return data; // return the response
}

/// Log out the user from the server.
Future<Map> logout(
    String ip, String token, String userID, String firebaseToken) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/logout"); // URL for request
  final body = jsonEncode({"userID": userID, "firebaseToken": firebaseToken});
  final response =
      await http.post(url, body: body, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to logout"
    }; // return error if status code is not 200
  }
  return {"message": "Logged out"}; // return the response
}

/// Retrieve user data from the server.
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

/// Retrieve the profile picture of a user from the server.
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

/// Edit user data on the server.
Future<Map> editUser(String ip, String token, String userID, Map data) async {
  if (data["profilePicture"] == null) {
    // if no profile picture is provided
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }; // headers for request
    final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
    final response = await http.put(url,
        body: jsonEncode(data), headers: headers); // post request
    if (response.statusCode != 200) {
      return {
        "message": "Failed to update user"
      }; // return error if status code is not 200
    }
    return {"message": "User updated successfully"}; // return the response
  }
  final headers = {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/users/$userID"); // URL for request
  var request = http.MultipartRequest("PUT", url); // create multipart request
  request.headers.addAll(headers); // add headers to request
  request.fields['userData'] = jsonEncode(data); // add user data to request
  request.files.add(await http.MultipartFile.fromPath(
    'profilePicture',
    data["profilePicture"],
    contentType: MediaType("image", "jpeg"),
  )); // add profile picture to request
  final response = await request.send(); // send the request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to update user"
    }; // return error if status code is not 200
  }
  return {"message": "User updated successfully"}; // return the response
}

/// Delete the profile picture of a user from the server.
Future<Map<String, dynamic>> deleteProfilePicture(
    String ip, String token, String userID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url =
      Uri.http("$ip:8080", "/profile_picture/$userID"); // URL for request
  final response = await http.delete(url, headers: headers); // delete request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to delete profile picture"
    }; // return error if status code is not 200
  }
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Delete a user from the server.
Future<Map<String, dynamic>> deleteUser(
    String ip, String token, String userID) async {
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

/// Recover a user's password by sending a recovery email.
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

/// Reset a user's password using a recovery code.
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

/// Add a dog to the user's profile on the server.
Future<Map<String, dynamic>> addDog(
    String ip, String token, String userID, Map data) async {
  if (data["Picture"] == null) {
    // if no picture is provided
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }; // headers for request
    final url = Uri.http("$ip:8080", "/dogs/$userID"); // URL for request
    final response = await http.post(url,
        body: jsonEncode(data), headers: headers); // post request
    if (response.statusCode != 200) {
      return {
        "message": "Failed to add dog"
      }; // return error if status code is not 200
    }
    return {"message": "Dog added"}; // return the response
  }
  final headers = {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/dogs/$userID"); // URL for request
  var request = http.MultipartRequest("POST", url); // create multipart request
  request.headers.addAll(headers); // add headers to request
  request.fields['dogData'] = jsonEncode(data); // add dog data to request
  request.files.add(await http.MultipartFile.fromPath(
    'dogPicture',
    data["Picture"],
    contentType: MediaType("image", "jpeg"),
  )); // add dog picture to request
  final response = await request.send(); // send the request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to add dog"
    }; // return error if status code is not 200
  }
  return {"message": "Dog added"}; // return the response
}

/// Edit a dog's data on the server.
Future<Map<String, dynamic>> editDog(
    String ip, String token, String userID, Map data) async {
  String dogID = data["dogID"];
  if (data["Picture"] == null) {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }; // headers for request
    final url = Uri.http("$ip:8080", "/dogs/$userID/$dogID"); // URL for request
    final response = await http.put(url,
        body: jsonEncode(data), headers: headers); // post request
    if (response.statusCode != 200) {
      return {
        "message": "Failed to update dog"
      }; // return error if status code is not 200
    }
    return {"message": "Dog updated successfully"}; // return the response
  }
  final headers = {
    'Content-Type': 'multipart/form-data',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/dogs/$userID/$dogID"); // URL for request
  var request = http.MultipartRequest("PUT", url);
  request.headers.addAll(headers);
  request.fields['dogData'] = jsonEncode(data);
  request.files.add(await http.MultipartFile.fromPath(
    'dogPicture',
    data["Picture"],
    contentType: MediaType("image", "jpeg"),
  ));
  final response = await request.send();
  if (response.statusCode != 200) {
    return {
      "message": "Failed to update dog"
    }; // return error if status code is not 200
  }
  return {"message": "Dog updated successfully"}; // return the response
}

/// Retrieve a dog's picture from the server.
Future<Uint8List?> getDogPicture(
    String ip, String userID, String dogID, String token) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/dog_picture/$userID/$dogID");
  final response = await http.get(url, headers: headers); // get request

  if (response.statusCode == 200) {
    return response.bodyBytes; // Get the raw image bytes
  }
  return null;
}

/// Delete a dog's picture from the server.
Future<Map<String, dynamic>> deleteDogPicture(
    String ip, String token, String userID, String dogID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url =
      Uri.http("$ip:8080", "/dog_picture/$userID/$dogID"); // URL for request
  final response = await http.delete(url, headers: headers); // delete request
  if (response.statusCode != 200) {
    return {"message": "Failed to delete profile picture"};
  } // return error if status code is not 200
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Delete a dog from the user's profile on the server.
Future<Map<String, dynamic>> deleteDog(
    String ip, String token, String userID, String dogID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "/dogs/$userID/$dogID"); // URL for request
  final response = await http.delete(url, headers: headers); // delete request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to delete dog"
    }; // return error if status code is not 200
  }
  return {
    "message": "Dog $dogID of user $userID deleted successfully"
  }; // return success message
}

/// Retrieve a list of stores from the server.
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

/// Retrieve a list of breeds from the server.
Future<List> getBreeds(String ip, String token) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8080", "breeds"); // url for request
  final response = await http.get(url, headers: headers); // get request
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to get breeds"); // throw exception if status code is not 200
  }
  List tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Retrieve a list of reservations for a user from the server.
Future<List<Map<String, dynamic>>> getReservations(
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
  List<Map<String, dynamic>> tmp = List<Map<String, dynamic>>.from(
      jsonDecode(response.body)); // decode the response
  return tmp; // return the response
}

/// Reserve a kennel for a dog on the server.
Future<Map> reserve(String ip, String token, Map data) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/reserve"); // URL for request
  final response = await http.post(url,
      body: jsonEncode(data), headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to reserve"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Activate a reservation for a dog on the server.
Future<Map> activate_reservation(
    String ip, String token, String reservationID, int unlockCode) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final body = jsonEncode({"unlockCode": unlockCode});
  final url =
      Uri.http("$ip:8083", "/activate/$reservationID"); // URL for request
  final response =
      await http.post(url, headers: headers, body: body); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to activate reservation"
    }; // return error if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Cancel a reservation for a dog on the server.
Future<Map> cancel_reservation(
    String ip, String token, String reservationID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/cancel/$reservationID"); // URL for request
  final response = await http.delete(url, headers: headers); // post request
  if (response.statusCode != 200) {
    return {
      "message": "Failed to cancel reservation"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Unlock a kennel for a dog on the server.
Future<Map> unlock_kennel(String ip, String token, Map data) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }; // headers for request
  final url = Uri.http("$ip:8083", "/unlock"); // URL for request
  final response = await http.post(url,
      body: jsonEncode(data), headers: headers); // post request
  if (response.statusCode != 200) {
    if (response.statusCode == 404) {
      return {
        "message": "Kennel not suitable for your dog size or not available"
      }; // return error if status code is 404
    }
    return {
      "message": "Failed to unlock kennel"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

/// Get the temperature and humidity from the kennel's sensors.
Future<List<double>> getTemperatureHumidity(String ip) async {
  final headers = {
    'Content-Type': 'application/json',
  }; // headers for request
  final url = Uri.http("$ip:8082"); // URL for request
  final response = await http.get(url, headers: headers); // get request
  if (response.statusCode != 200) {
    return [-1, -1];
  }
  Map tmp = jsonDecode(response.body);
  List values = tmp["e"];
  double temperature = 1000;
  double humidity = 1000;
  for (Map measurement in values) {
    if (measurement["n"] == "humidity") {
      humidity = double.parse(measurement["v"].toString());
    }
    if (measurement["n"] == "temperature") {
      temperature = double.parse(measurement["v"].toString());
    }
  }
  return [temperature, humidity];
}

/// Get the kennel measurements from the Thingspeak API.
Future<Map> getKennelmeasurements(
    String ip, int kennelID, int activationTime) async {
  String settingsString = await rootBundle
      .loadString("assets/settings.json"); // Load the settings from the assets
  Map<String, dynamic> settings =
      jsonDecode(settingsString); // Decode the settings
  final int channelID =
      settings["channel_id"]; // Get the channel ID from the settings
  final String readApiKey = settings[
      "thingspeak_read_api_key"]; // Get the read API key from the settings
  final dateTimeUtc = DateTime.fromMillisecondsSinceEpoch(activationTime * 1000,
      isUtc: true); // Convert the activation time to a DateTime in UTC
  // Format DateTime in YYYY-MM-DD HH:MM:SS
  final year = dateTimeUtc.year.toString(); // Get the year from the DateTime
  final month = dateTimeUtc.month.toString().padLeft(2,
      '0'); // Get the month from the DateTime and pad it with a leading zero if necessary
  final day = dateTimeUtc.day.toString().padLeft(2,
      '0'); // Get the day from the DateTime and pad it with a leading zero if necessary
  final hour = dateTimeUtc.hour.toString().padLeft(2,
      '0'); // Get the hour from the DateTime and pad it with a leading zero if necessary
  final minute = dateTimeUtc.minute.toString().padLeft(2,
      '0'); // Get the minute from the DateTime and pad it with a leading zero if necessary
  final second = dateTimeUtc.second.toString().padLeft(2,
      '0'); // Get the second from the DateTime and pad it with a leading zero if necessary
  // Create the formatted start date string as required by the Thingspeak API
  final formattedStartDate = '$year-$month-$day $hour:$minute:$second';
  final Map<String, String> params = {
    "api_key": readApiKey,
    "start": formattedStartDate
  }; // parameters for the request
  final url = Uri.https("api.thingspeak.com", "/channels/$channelID/feeds.json",
      params); // URL for the request to the Thingspeak API
  final response = await http.get(url); // post request
  if (response.statusCode != 200) {
    return {"Error": "Failed to get kennel measurements"};
  } // throw exception if status code is not 200
  Map<String, dynamic> tmp = jsonDecode(response.body); // decode the response
  List<Map<String, dynamic>> feeds =
      List<Map<String, dynamic>>.from(tmp["feeds"]); // decode the response
  final Map<String, dynamic> kennelMeasurements = {
    "temperature": [],
    "humidity": [],
  }; // create a map to store the kennel measurements
  for (var feed in feeds) {
    if (int.parse(feed["field4"]) == kennelID) {
      // Check if the feed belongs to the specified kennel ID
      if (feed["field1"] != null) {
        // Check if the temperature field is not null
        double? temp = double.tryParse(feed["field1"]);
        if (temp != null) {
          kennelMeasurements["temperature"].add({
            "timestamp": DateTime.parse(feed["created_at"]),
            "value": temp
          }); // Add the temperature measurement to the temperature list
        }
      }
      if (feed["field2"] != null) {
        // Check if the humidity field is not null
        double? hum = double.tryParse(feed["field2"]);
        if (hum != null) {
          kennelMeasurements["humidity"].add({
            "timestamp": DateTime.parse(feed["created_at"]),
            "value": hum
          }); // Add the humidity measurement to the humidity list
        }
      }
    }
  }
  return kennelMeasurements; // return the kennel measurements
}
