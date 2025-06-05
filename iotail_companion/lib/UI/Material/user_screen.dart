import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:iotail_companion/util/user.dart';
import 'package:iotail_companion/util/requests.dart' as requests;
import 'package:iotail_companion/util/tutorial_manager.dart';

final saveButtonKey =
    GlobalKey(); // Key for the save button to show the tutorial coach mark.

class UserScreen extends StatefulWidget {
  final User user; // User object containing user details.
  final String ip; // IP address of the server.
  final String token; // Authentication token for the user.
  final VoidCallback
      onEdit; // Callback function to be called when the user details are edited.

  const UserScreen(
      {super.key,
      required this.user,
      required this.ip,
      required this.token,
      required this.onEdit});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Uint8List? _pickedImage; // Variable to hold the picked image as bytes.
  late String _name; // Variable to hold the user's name.
  late String _email; // Variable to hold the user's email.
  late String _phone; // Variable to hold the user's phone number.
  String? _imagePath; // Variable to hold the path of the picked image.
  late final TextEditingController
      _nameController; // Controller for the name text field.
  late final TextEditingController
      _emailController; // Controller for the email text field.
  late final TextEditingController
      _phoneController; // Controller for the phone number text field.
  late FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Options for Android to use encrypted shared preferences for secure storage.
  final TutorialManager tutorialManager =
      TutorialManager(); // Instance of TutorialManager to manage user tutorials.

  /// Shows the coach mark for the save button after the widget is built.
  void _showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensures the coach mark is shown after the widget is built.
      storage.read(key: "userEditTutorialComplete").then((value) {
        // Reads the tutorial completion status from secure storage.
        if (value != 'completed') {
          ShowCaseWidget.of(context).startShowCase([
            saveButtonKey,
          ]); // Starts the showcase for the save button if it is the first time the user is accessing the screen.
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _pickedImage = widget.user
        .profilePicture; // Initializing the picked image with the user's profile picture.
    storage = FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initializing secure storage with Android options for encrypted shared preferences.
    _name = widget.user.name; // Initializing the user's name.
    _nameController = TextEditingController(
        text:
            _name); // Initializing the name text field controller with the user's name.
    _email = widget.user.email; // Initializing the user's email.
    _emailController = TextEditingController(
        text:
            _email); // Initializing the email text field controller with the user's email.
    _phone = widget.user.phoneNumber; // Initializing the user's phone number.
    _phoneController = TextEditingController(
        text:
            _phone); // Initializing the phone number text field controller with the user's phone number.
    _showCoachMark(); // Showing the coach mark for the save button after the widget is built.
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose(); // Disposing the name text field controller.
    _emailController.dispose(); // Disposing the email text field controller.
    _phoneController
        .dispose(); // Disposing the phone number text field controller.
  }

  /// Function to take an image from the camera
  Future<void> _captureImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      _imagePath = pickedFile.path;
      _pickedImage = await pickedFile.readAsBytes();
      setState(() {});
    }
  }

  /// Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      _imagePath = pickedFile.path;
      _pickedImage = await pickedFile.readAsBytes();
      setState(() {});
    }
  }

  /// Show a bottom sheet with options to capture an image from the camera, pick an image from the gallery, or delete the current user picture.
  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: 16),
          height: 150,
          child: Column(
            children: [
              Text(
                'Profile Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10), // Space between the title and the options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Option button to capture an image from the camera
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      context.pop(); // Close the bottom sheet
                      _captureImageFromCamera(); // Capture an image from the camera
                    },
                  ),
                  // Option button to pick an image from the gallery
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Library',
                    onTap: () {
                      context.pop(); // Close the bottom sheet
                      _pickImageFromGallery(); // Pick an image from the gallery
                    },
                  ),
                  // Option button for deleting the current dog picture to show only if a picture is already picked or already exists
                  if (_pickedImage != null && _pickedImage!.isNotEmpty)
                    _buildOptionButton(
                      icon: Icons.delete,
                      label: 'Cancel',
                      onTap: () {
                        context.pop(); // Close the bottom sheet
                        _showProfilePictureDeleteConfirmDialog(
                            context); // Show confirmation dialog for deleting the profile picture
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show a confirmation dialog to delete the profile picture.
  void _showProfilePictureDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Profile image'),
          content: Text('Are you sure you want to delete the profile image?'),
          actions: [
            // Button to confirm deletion of the profile picture
            TextButton(
              onPressed: () async {
                context.pop(); // Close the dialog
                Map<String, dynamic> message = await requests.deleteProfilePicture(
                    widget.ip,
                    widget.token,
                    widget.user
                        .userID); // Call the API to delete the profile picture
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  )); // Show a snackbar with the error message if the deletion fails
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Profile image deleted successfully"),
                  )); // Show a snackbar with success message if the deletion is successful
                  _imagePath = null; // Clear the image path
                  setState(() {
                    _pickedImage = null; // Clear the picked image
                  });
                  widget
                      .onEdit(); // Call the onEdit callback to notify that the user details have been edited
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context
                    .pop(); // Close the dialog without deleting the profile picture
              },
              child: Text('NO'),
            ),
          ],
        );
      },
    );
  }

  /// Show a confirmation dialog to delete the user account.
  void _showUserDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? The action is irreversible.'),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop();
                Map<String, dynamic> message = await requests.deleteUser(
                    widget.ip,
                    widget.token,
                    widget.user
                        .userID); // Call the API to delete the user account
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  )); // Show a snackbar with the error message if the deletion fails
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Account deleted successfully"),
                  )); // Show a snackbar with success message if the deletion is successful
                  storage.delete(
                      key: "email"); // Delete the email from secure storage
                  storage.delete(
                      key:
                          "password"); // Delete the password from secure storage
                  storage.delete(
                      key: "userID"); // Delete the userID from secure storage
                  storage.delete(
                      key: "token"); // Delete the token from secure storage
                  storage.delete(
                      key:
                          "dogEditTutorialComplete"); // Delete the dog edit tutorial completion status from secure storage
                  storage.delete(
                      key:
                          "userEditTutorialComplete"); // Delete the user edit tutorial completion status from secure storage
                  await TutorialManager
                      .resetUserSession(); // Reset the main tutarial manager session (Navigation, dog, reservation)
                  context.go("/Login",
                      extra: widget
                          .ip); // Navigate to the Login page, passing the IP address as an extra parameter
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context
                    .pop(); // Close the dialog without deleting the user account
              },
              child: Text('NO'),
            ),
          ],
        );
      },
    );
  }

  /// Build a button with an icon, label and onTap callback for the bottom sheet options.
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
              bounds), // Gradient for the title text from top left to bottom right
          child: const Text(
            'IoTail',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SafeArea(
        // Safe area to avoid notches and system UI overlaps
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    // Displaying the user's profile picture or a default image if no picture is picked
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: _pickedImage == null || _pickedImage!.isEmpty
                                ? Icon(
                                    Icons.account_circle_outlined,
                                    size: 150,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ) // Default icon if no image is picked
                                : CircleAvatar(
                                    radius: 75,
                                    backgroundImage: Image.memory(_pickedImage!)
                                        .image) // Displaying the picked image as a CircleAvatar
                            ),
                        // Button to open the bottom sheet for image options
                        GestureDetector(
                          onTap: () => _showBottomSheet(context),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.edit_outlined,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height:
                            16), // Space between the profile picture and the text fields
                    // Text fields for editing user details
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _nameController,
                        onChanged: (value) {
                          _name = value;
                        },
                        decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _emailController,
                        onChanged: (value) {
                          _email = value;
                        },
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _phoneController,
                        onChanged: (value) {
                          _phone = value;
                        },
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    // Save button with showcase tutorial
                    Showcase(
                      key: saveButtonKey,
                      titleAlignment: Alignment.centerLeft,
                      title: "Save Changes",
                      titleTextStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      descriptionAlignment: Alignment.centerLeft,
                      description:
                          "Remember to save your changes before going back to homescreen.",
                      descTextStyle: Theme.of(context).textTheme.bodyMedium,
                      tooltipBackgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      targetBorderRadius: BorderRadius.circular(10),
                      tooltipActions: [
                        TooltipActionButton(
                            type: TooltipDefaultActionType.next,
                            name: "Finish",
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            onTap: () {
                              ShowCaseWidget.of(context)
                                  .dismiss(); // Dismiss the showcase tutorial
                              storage.write(
                                  key: "userEditTutorialComplete",
                                  value:
                                      "completed"); // Mark the user edit tutorial as completed
                            }),
                      ],
                      child: ElevatedButton(
                        onPressed: () async {
                          Map tmp = {
                            "name": _name,
                            "email": _email,
                            "phoneNumber": _phone,
                            "profilePicture": _imagePath,
                          }; // Temporary map to hold the updated user details
                          final response = await requests.editUser(
                              widget.ip,
                              widget.token,
                              widget.user.userID,
                              tmp); // Call the API to edit the user details
                          if (response["message"]
                              .toString()
                              .contains("Failed")) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(response["message"]),
                            )); // Show a snackbar with the error message if the edit fails
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("User edited successfully"),
                          )); // Show a snackbar with success message if the edit is successful
                          storage.write(
                              key: "email",
                              value: _emailController
                                  .text); // Save the updated email to secure storage
                          widget
                              .onEdit(); // Call the onEdit callback to notify that the user details have been edited
                        },
                        style: ButtonStyle(
                          elevation: WidgetStateProperty.all(8),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                          backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer),
                          minimumSize: WidgetStateProperty.all(
                              Size(double.infinity, 50)),
                          padding: WidgetStateProperty.all(EdgeInsets.all(8)),
                        ),
                        child: Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ), // Space between the save button and the logout button
                    // Logout button
                    ElevatedButton(
                      onPressed: () async {
                        final String? firebaseToken = await storage.read(
                            key:
                                "FirebaseToken"); // Reading the Firebase token from secure storage
                        final response = await requests.logout(
                            widget.ip,
                            widget.token,
                            widget.user.userID,
                            firebaseToken!); // Call the API to log out the user
                        if (response["message"].toString().contains("Failed")) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response["message"]),
                          )); // Show a snackbar with the error message if the logout fails
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Logged out successfully"),
                        )); // Show a snackbar with success message if the logout is successful
                        storage.delete(
                            key: "email"); // Delete the email from the storage
                        storage.delete(
                            key:
                                "password"); // Delete the password from the storage
                        storage.delete(
                            key:
                                "userID"); // Delete the userID from the storage
                        storage.delete(
                            key: "token"); // Delete the token from the storage
                        context.go("/Login",
                            extra: widget
                                .ip); // Navigate to the Login page, passing the IP address as an extra parameter
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        side: WidgetStateProperty.all(
                            BorderSide(color: Colors.red)),
                        minimumSize:
                            WidgetStateProperty.all(Size(double.infinity, 50)),
                        padding: WidgetStateProperty.all(EdgeInsets.all(8)),
                      ),
                      child: const Text(
                        "LOGOUT",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ), // Space between the logout button and the delete account button
                    // Delete account button
                    ElevatedButton(
                      onPressed: () => _showUserDeleteConfirmDialog(
                          context), // Show confirmation dialog for deleting the user account
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                        backgroundColor: WidgetStateProperty.all(Colors.red),
                        side: WidgetStateProperty.all(
                            BorderSide(color: Colors.white)),
                        minimumSize:
                            WidgetStateProperty.all(Size(double.infinity, 50)),
                        padding: WidgetStateProperty.all(EdgeInsets.all(8)),
                      ),
                      child: Text(
                        "DELETE ACCOUNT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
