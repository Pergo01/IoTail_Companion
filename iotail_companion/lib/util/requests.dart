import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

Future<Map> editUser(String ip, String token, String userID, Map data) async {
  if (data["profilePicture"] == null) {
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
      "message": "Failed to update user"
    }; // return error if status code is not 200
  }
  return {"message": "User updated successfully"}; // return the response
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

Future<Map<String, dynamic>> addDog(
    String ip, String token, String userID, Map data) async {
  if (data["Picture"] == null) {
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
  var request = http.MultipartRequest("POST", url);
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
      "message": "Failed to add dog"
    }; // return error if status code is not 200
  }
  return {"message": "Dog added"}; // return the response
}

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

Future<Map<String, dynamic>> deleteDogPicture(
    String ip, String token, String userID, String dogID) async {
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  final url = Uri.http("$ip:8080", "/dog_picture/$userID/$dogID");
  final response = await http.delete(url, headers: headers);
  if (response.statusCode != 200) {
    return {"message": "Failed to delete profile picture"};
  }
  Map<String, dynamic> tmp = jsonDecode(response.body);
  return tmp;
}

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
      };
    }
    return {
      "message": "Failed to unlock kennel"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

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
    }; // throw exception if status code is not 200
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
    return {
      "message": "Failed to cancel reservation"
    }; // throw exception if status code is not 200
  }
  Map tmp = jsonDecode(response.body); // decode the response
  return tmp; // return the response
}

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

Future<Map> getKennelmeasurements(
    String ip, int kennelID, int activationTime) async {
  String settingsString = await rootBundle.loadString("assets/settings.json");
  Map<String, dynamic> settings = jsonDecode(settingsString);
  final int channelID = settings["channel_id"];
  final String readApiKey = settings["thingspeak_read_api_key"];
  final dateTimeUtc =
      DateTime.fromMillisecondsSinceEpoch(activationTime * 1000, isUtc: true);
  // Formatta DateTime in AAAA-MM-GG HH:NN:SS
  final year = dateTimeUtc.year.toString();
  final month = dateTimeUtc.month.toString().padLeft(2, '0');
  final day = dateTimeUtc.day.toString().padLeft(2, '0');
  final hour = dateTimeUtc.hour.toString().padLeft(2, '0');
  final minute = dateTimeUtc.minute.toString().padLeft(2, '0');
  final second = dateTimeUtc.second.toString().padLeft(2, '0');
  // Crea la stringa finale con il separatore %20
  final formattedStartDate = '$year-$month-$day $hour:$minute:$second';
  final Map<String, String> params = {
    "api_key": readApiKey,
    "start": formattedStartDate
  };
  final url = Uri.https(
      "api.thingspeak.com", "/channels/$channelID/feeds.json", params);
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
  };
  var mintemp = double.infinity;
  for (var feed in feeds) {
    debugPrint("${feed["entry_id"]}");
    if (feed["entry_id"] == 112) {
      debugPrint("Found entry id 112");
    }
    if (int.parse(feed["field4"]) == kennelID) {
      if (feed["field1"] != null) {
        double? temp = double.tryParse(feed["field1"]);
        if (temp != null && temp < mintemp) {
          mintemp = temp;
        }
        if (temp != null) {
          kennelMeasurements["temperature"].add(
              {"timestamp": DateTime.parse(feed["created_at"]), "value": temp});
        }
      }
      if (feed["field2"] != null) {
        double? hum = double.tryParse(feed["field2"]);
        if (hum != null) {
          kennelMeasurements["humidity"].add(
              {"timestamp": DateTime.parse(feed["created_at"]), "value": hum});
        }
      }
    }
  }
  return kennelMeasurements;
}
