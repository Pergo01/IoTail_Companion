import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:iotail_companion/util/user.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

final saveButtonKey = GlobalKey();

class UserScreen extends StatefulWidget {
  final User user;
  final String ip;
  final String token;
  final VoidCallback onEdit;

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
  Uint8List? _pickedImage;
  late String _name;
  late String _email;
  late String _phone;
  String? _imagePath;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late FlutterSecureStorage storage;
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  void _showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([
        saveButtonKey,
      ]);
    });
  }

  @override
  void initState() {
    super.initState();
    _pickedImage = widget.user.profilePicture;
    storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    _name = widget.user.name;
    _nameController = TextEditingController(text: _name);
    _email = widget.user.email;
    _emailController = TextEditingController(text: _email);
    _phone = widget.user.phoneNumber;
    _phoneController = TextEditingController(text: _phone);
    _showCoachMark();
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
  }

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
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      context.pop();
                      _captureImageFromCamera();
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Library',
                    onTap: () {
                      context.pop();
                      _pickImageFromGallery();
                    },
                  ),
                  if (_pickedImage != null && _pickedImage!.isNotEmpty)
                    _buildOptionButton(
                      icon: Icons.delete,
                      label: 'Cancel',
                      onTap: () {
                        context.pop();
                        _showProfilePictureDeleteConfirmDialog(context);
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

  void _showProfilePictureDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Profile image'),
          content: Text('Are you sure you want to delete the profile image?'),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop();
                Map<String, dynamic> message =
                    await requests.deleteProfilePicture(
                        widget.ip, widget.token, widget.user.userID);
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Profile image deleted successfully"),
                  ));
                  _imagePath = null;
                  setState(() {
                    _pickedImage = null;
                  });
                  widget.onEdit();
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text('NO'),
            ),
          ],
        );
      },
    );
  }

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
                    widget.ip, widget.token, widget.user.userID);
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Account deleted successfully"),
                  ));
                  storage.delete(key: "email");
                  storage.delete(key: "password");
                  storage.delete(key: "userID");
                  storage.delete(key: "token");
                  context.go("/Login", extra: widget.ip);
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text('NO'),
            ),
          ],
        );
      },
    );
  }

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
          ).createShader(bounds),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
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
                                  )
                                : CircleAvatar(
                                    radius: 75,
                                    backgroundImage:
                                        Image.memory(_pickedImage!).image)),
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
                    SizedBox(height: 16),
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
                      targetBorderRadius: BorderRadius.circular(30),
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
                              ShowCaseWidget.of(context).dismiss();
                            }),
                      ],
                      child: ElevatedButton(
                        onPressed: () async {
                          Map tmp = {
                            "name": _name,
                            "email": _email,
                            "phoneNumber": _phone,
                            "profilePicture": _imagePath,
                          };
                          final response = await requests.editUser(
                              widget.ip, widget.token, widget.user.userID, tmp);
                          if (response["message"]
                              .toString()
                              .contains("Failed")) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(response["message"]),
                            ));
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("User edited successfully"),
                          ));
                          storage.write(
                              key: "email", value: _emailController.text);
                          widget.onEdit();
                        },
                        style: ButtonStyle(
                          elevation: WidgetStateProperty.all(8),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                          backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer),
                          // side: WidgetStateProperty.all(
                          //     BorderSide(color: Colors.red)),
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
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final String? firebaseToken =
                            await storage.read(key: "FirebaseToken");
                        final response = await requests.logout(widget.ip,
                            widget.token, widget.user.userID, firebaseToken!);
                        if (response["message"].toString().contains("Failed")) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response["message"]),
                          ));
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Logged out successfully"),
                        ));
                        storage.delete(key: "email");
                        storage.delete(key: "password");
                        storage.delete(key: "userID");
                        context.go("/Login", extra: widget.ip);
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
                    ),
                    ElevatedButton(
                      onPressed: () => _showUserDeleteConfirmDialog(context),
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
