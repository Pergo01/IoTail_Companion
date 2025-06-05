import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:iotail_companion/util/dog.dart';
import 'package:iotail_companion/util/breed.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

final dogSaveButtonKey =
    GlobalKey(); // Key for the save button showcase tutorial

/// The screen that allows the user to add, edit, or delete a dog.
class DogScreen extends StatefulWidget {
  final Dog dog; // Dog object containing all the dog details
  final List<Breed> breeds; // List of breeds to choose from
  final String userID; // User ID for API requests
  final String ip; // IP address of the server
  final String token; // Authentication token for API requests
  final VoidCallback
      onEdit; // Callback function to refresh the dog list after adding, editing, or deleting a dog

  const DogScreen(
      {super.key,
      required this.dog,
      required this.breeds,
      required this.userID,
      required this.ip,
      required this.token,
      required this.onEdit});

  @override
  _DogScreenState createState() => _DogScreenState();
}

class _DogScreenState extends State<DogScreen> {
  late FlutterSecureStorage
      storage; // Declaring secure storage variable for persistently storing data or writing precedently stored data. This allows to persist information after the app is closed.
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      ); // Options for Android secure storage

  // Variables to hold the dog details
  Uint8List? _pickedImage;
  late String _name;
  late String _breed;
  late int _breedID;
  late int _age;
  late String _sex;
  late String _size;
  late double _weight;
  late String _coatType;
  late List<String> _allergies;
  String? _imagePath;

  // Controllers for the text fields, search bar and expandable tiles
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _nameController;
  late final SearchController _breedSearchController;
  late final TextEditingController _ageController;
  final ExpansibleController _sexController = ExpansibleController();
  final ExpansibleController _sizeController = ExpansibleController();
  late final TextEditingController _weightController;
  final ExpansibleController _coatTypeController = ExpansibleController();
  late final TextEditingController _allergiesController;

  // Mixed Breed fields
  late double _maxIdealTemperature;
  late double _minIdealTemperature;
  late double _maxIdealHumidity;
  late double _minIdealHumidity;
  late TextEditingController _maxIdealTemperatureController;
  late TextEditingController _minIdealTemperatureController;
  late TextEditingController _maxIdealHumidityController;
  late TextEditingController _minIdealHumidityController;

  /// Function to show the tutorial for the save button only when the screen is first opened.
  void _showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storage.read(key: "dogEditTutorialComplete").then((value) {
        // Wait for the value and then check if it is 'completed'
        if (value != 'completed') {
          _scrollController.jumpTo(_scrollController.position
              .maxScrollExtent); // Scroll to the bottom of the screen to show the save button
          ShowCaseWidget.of(context).startShowCase([
            dogSaveButtonKey,
          ]); // Start the showcase tutorial for the save button
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    storage = FlutterSecureStorage(
        aOptions:
            _getAndroidOptions()); // Initialize secure storage with Android options
    // Initialize the variables and the textfield/search controllers with the dog details coming from the home screen
    _pickedImage = widget
        .dog.picture; // If the dog has a picture, set it to the picked image
    _name = widget.dog.name;
    _nameController =
        TextEditingController(text: widget.dog.name != "" ? _name : null);
    _breedID = widget.dog.breedID;
    _breed = widget.dog.breedID != -1
        ? widget.breeds
            .firstWhere((breed) => breed.breedID == widget.dog.breedID)
            .name
        : "";
    _breedSearchController = SearchController();
    _breedSearchController.text = _breed;
    _age = widget.dog.age;
    _ageController = TextEditingController(
        text: widget.dog.age != 0 ? _age.toString() : null);
    _sex = widget.dog.sex == 0 ? "Male" : "Female";
    _size = widget.dog.size;
    _weight = widget.dog.weight;
    _weightController = TextEditingController(
        text: widget.dog.weight != 0.0 ? _weight.toString() : null);
    _coatType = widget.dog.coatType;
    _allergies = widget.dog.allergies;
    _allergiesController = TextEditingController(
        text: widget.dog.allergies != [] ? _allergies.join(", ") : null);
    // Mixed Breed fields
    _maxIdealTemperature = widget.dog.maxIdealTemperature ?? 0.0;
    _minIdealTemperature = widget.dog.minIdealTemperature ?? 0.0;
    _maxIdealHumidity = widget.dog.maxIdealHumidity ?? 0.0;
    _minIdealHumidity = widget.dog.minIdealHumidity ?? 0.0;
    _maxIdealTemperatureController = TextEditingController(
        text: _maxIdealTemperature != 0.0
            ? _maxIdealTemperature.toString()
            : null);
    _minIdealTemperatureController = TextEditingController(
        text: _minIdealTemperature != 0.0
            ? _minIdealTemperature.toString()
            : null);
    _maxIdealHumidityController = TextEditingController(
        text: _maxIdealHumidity != 0.0 ? _maxIdealHumidity.toString() : null);
    _minIdealHumidityController = TextEditingController(
        text: _minIdealHumidity != 0.0 ? _minIdealHumidity.toString() : null);

    if (widget.dog.dogID != "") {
      // If a dog is being added, do not show the tutorial
      _showCoachMark();
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose of the controllers to free up resources
    _nameController.dispose();
    _breedSearchController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
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

  /// Show a bottom sheet with options to capture an image from the camera, pick an image from the gallery, or delete the current dog picture.
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
              SizedBox(height: 10), // Space between title and options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Option button for camera
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      context.pop(); // Close the bottom sheet
                      _captureImageFromCamera(); // Capture image from camera
                    },
                  ),
                  // Option button for gallery
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Library',
                    onTap: () {
                      context.pop(); // Close the bottom sheet
                      _pickImageFromGallery(); // Pick image from gallery
                    },
                  ),
                  // Option button for deleting the current dog picture to show only if a picture is already picked or already exists
                  if (_pickedImage != null && _pickedImage!.isNotEmpty)
                    _buildOptionButton(
                      icon: Icons.delete,
                      label: 'Cancel',
                      onTap: () {
                        context.pop(); // Close the bottom sheet
                        _showDogPictureDeleteConfirmDialog(
                            context); // Show confirmation dialog to delete the dog picture
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

  /// Dialog to confirm the deletion of the dog's picture.
  void _showDogPictureDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Dog image'),
          content: Text('Are you sure you want to delete the dog\'s image?'),
          actions: [
            // Button for confirming the deletion of the dog's picture
            TextButton(
              onPressed: () async {
                context.pop(); // Close the dialog
                Map<String, dynamic> message = await requests.deleteDogPicture(
                    widget.ip,
                    widget.token,
                    widget.userID,
                    widget.dog
                        .dogID); // Make API request to delete the dog picture
                if (message["message"].contains("Failed")) {
                  // If the request failed, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  // If the request was successful, show a success message and update the state
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Dog image deleted successfully"),
                  ));
                  _imagePath = null;
                  setState(() {
                    _pickedImage = null;
                  });
                  widget
                      .onEdit(); // Call the onEdit callback to refresh the dog list in the home screen and then the navigation
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context.pop(); // Close the dialog without doing anything
              },
              child: Text('NO'),
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog to confirm the deletion of the dog.
  void _showDogDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Dog'),
          content: Text('Are you sure you want to delete the dog?'),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop(); // Close the dialog
                Map<String, dynamic> message = await requests.deleteDog(
                    widget.ip,
                    widget.token,
                    widget.userID,
                    widget.dog.dogID); // Make API request to delete the dog
                if (message["message"].contains("Failed")) {
                  // If the request failed, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  // If the request was successful, show a success message and update the state
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Dog deleted successfully"),
                  ));
                  context.pop(); // Go back to the home screen
                  widget
                      .onEdit(); // Call the onEdit callback to refresh the dog list in the home screen and then the navigation
                }
              },
              child: Text('YES'),
            ),
            TextButton(
              onPressed: () {
                context.pop(); // Close the dialog without doing anything
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
      resizeToAvoidBottomInset: true,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Display the dog's picture or a default image if no picture is picked
                      Container(
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: _pickedImage == null || _pickedImage!.isEmpty
                              ? Image.asset(
                                  "assets/default_cane.jpeg", // Default image if no picture is picked
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover)
                              : Image.memory(
                                  _pickedImage!, // Display the picked image or the existing image
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover)),
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
                          16), // Space between the image and the text fields
                  // Text fields for editing dog details
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
                        hintText: "Your dog's name",
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        labelText: "Breed",
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
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: SearchAnchor.bar(
                          barBackgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surface),
                          barShape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          barElevation: WidgetStateProperty.all(0),
                          barPadding:
                              WidgetStateProperty.all(EdgeInsets.all(4)),
                          barLeading: SizedBox.shrink(),
                          barTrailing: [
                            Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          ],
                          isFullScreen: false,
                          searchController: _breedSearchController,
                          onTap: () {
                            _breedSearchController.clear();
                          },
                          suggestionsBuilder: (BuildContext context,
                              SearchController controller) {
                            if (controller.text.isEmpty) {
                              return widget.breeds.map((breed) => ListTile(
                                    title: Text(breed.name),
                                    onTap: () {
                                      setState(() {
                                        _breed = breed.name;
                                        _breedID = breed.breedID;
                                      });
                                      controller.closeView(breed.name);
                                    },
                                  ));
                            }
                            return widget.breeds
                                .where((breed) => breed.name
                                    .toLowerCase()
                                    .contains(controller.text.toLowerCase()))
                                .map((breed) => ListTile(
                                      title: Text(breed.name),
                                      onTap: () {
                                        setState(() {
                                          _breed = breed.name;
                                          _breedID = breed.breedID;
                                        });
                                        controller.closeView(breed.name);
                                      },
                                    ));
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _ageController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _age = int.parse(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Age",
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
                        hintText: "Your dog's age",
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        labelText: "Sex",
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
                      child: ExpansionTile(
                        controller: _sexController,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        iconColor: Theme.of(context).colorScheme.primary,
                        collapsedIconColor:
                            Theme.of(context).colorScheme.primary,
                        title: Text(
                          _sex,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        children: [
                          if (_sex != "Male")
                            ListTile(
                              title: Text("Male",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _sex = "Male";
                                });
                                _sexController.collapse();
                              },
                            ),
                          if (_sex != "Female")
                            ListTile(
                              title: Text(
                                "Female",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              onTap: () {
                                setState(() {
                                  _sex = "Female";
                                });
                                _sexController.collapse();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          labelText: "Size",
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
                          helperText:
                              "Small: <35cm, Medium: 35cm-50cm, Large: 50cm+",
                          helperStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                      child: ExpansionTile(
                        controller: _sizeController,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        iconColor: Theme.of(context).colorScheme.primary,
                        collapsedIconColor:
                            Theme.of(context).colorScheme.primary,
                        title: Text(_size,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
                        children: [
                          if (_size != "Small")
                            ListTile(
                              title: Text("Small",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _size = "Small";
                                });
                                _sizeController.collapse();
                              },
                            ),
                          if (_size != "Medium")
                            ListTile(
                              title: Text("Medium",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _size = "Medium";
                                });
                                _sizeController.collapse();
                              },
                            ),
                          if (_size != "Large")
                            ListTile(
                              title: Text("Large",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _size = "Large";
                                });
                                _sizeController.collapse();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: _weightController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _weight = double.parse(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Weight",
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
                        hintText: "Your dog's weight",
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        labelText: "Coat type",
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
                      child: ExpansionTile(
                        controller: _coatTypeController,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        iconColor: Theme.of(context).colorScheme.primary,
                        collapsedIconColor:
                            Theme.of(context).colorScheme.primary,
                        title: Text(_coatType,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
                        children: [
                          if (_coatType != "Short")
                            ListTile(
                              title: Text("Short",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _coatType = "Short";
                                });
                                _coatTypeController.collapse();
                              },
                            ),
                          if (_coatType != "Medium")
                            ListTile(
                              title: Text("Medium",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _coatType = "Medium";
                                });
                                _coatTypeController.collapse();
                              },
                            ),
                          if (_coatType != "Long")
                            ListTile(
                              title: Text("Long",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                              onTap: () {
                                setState(() {
                                  _coatType = "Long";
                                });
                                _coatTypeController.collapse();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _allergiesController,
                      onChanged: (value) {
                        _allergies = value.trim().split(", ");
                      },
                      decoration: InputDecoration(
                        labelText: "Allergies",
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
                        hintText: "Your dog's allergies, separated by commas",
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_breedID ==
                      0) // If the breed is "Mixed Breed", show additional field for min ideal temperature
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _minIdealTemperatureController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _minIdealTemperature = double.parse(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Minimal tolerated temperature (°C)",
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
                          hintText: "Your dog's minimal tolerated temperature",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_breedID ==
                      0) // If the breed is "Mixed Breed", show additional field for max ideal temperature
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _maxIdealTemperatureController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _maxIdealTemperature = double.parse(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Maximal tolerated temperature (°C)",
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
                          hintText: "Your dog's maximal tolerated temperature",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_breedID ==
                      0) // If the breed is "Mixed Breed", show additional field for min ideal humidity
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _minIdealHumidityController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _minIdealHumidity = double.parse(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Minimal tolerated humidity (%)",
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
                          hintText: "Your dog's minimal tolerated humidity",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_breedID ==
                      0) // If the breed is "Mixed Breed", show additional field for max ideal humidity
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _maxIdealHumidityController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _maxIdealHumidity = double.parse(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Maximal tolerated humidity (%)",
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
                          hintText: "Your dog's maximal tolerated humidity",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  // Save button with showcase tutorial if the dog is being edited
                  Showcase(
                    key:
                        widget.dog.dogID != "" ? dogSaveButtonKey : GlobalKey(),
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
                                .dismiss(); // Dismiss the showcase
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // Scroll to the top of the screen only after the frame is built (i.e. after the showcase is dismissed)
                              _scrollController.animateTo(
                                  _scrollController.position.minScrollExtent,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInOut);
                            });
                            storage.write(
                                key: "dogEditTutorialComplete",
                                value:
                                    "completed"); // Mark this tutorial as completed
                          }),
                    ],
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_breedID == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please select a breed"),
                          )); // Show error if no breed is selected
                          return;
                        }
                        Map tmp = _breedID !=
                                0 // If the breed is not "Mixed Breed" do not include ideal temperature and humidity fields
                            ? {
                                "dogID": widget.dog.dogID,
                                "name": _name,
                                "breedID": _breedID,
                                "age": _age,
                                "sex": _sex == "Male" ? 0 : 1,
                                "size": _size,
                                "weight": _weight,
                                "coatType": _coatType,
                                "allergies": _allergies,
                                "Picture": _imagePath,
                              }
                            : {
                                "dogID": widget.dog.dogID,
                                "name": _name,
                                "breedID": _breedID,
                                "age": _age,
                                "sex": _sex == "Male" ? 0 : 1,
                                "size": _size,
                                "weight": _weight,
                                "coatType": _coatType,
                                "minIdealTemperature": _minIdealTemperature,
                                "maxIdealTemperature": _maxIdealTemperature,
                                "minIdealHumidity": _minIdealHumidity,
                                "maxIdealHumidity": _maxIdealHumidity,
                                "allergies": _allergies,
                                "Picture": _imagePath,
                              };
                        final response = widget.dog.dogID == ""
                            ? await requests.addDog(
                                widget.ip,
                                widget.token,
                                widget.userID,
                                tmp) // if dogID is empty, add a new dog
                            : await requests.editDog(
                                widget.ip,
                                widget.token,
                                widget.userID,
                                tmp); // if dogID is not empty, edit the existing dog
                        if (response["message"].toString().contains("Failed")) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response["message"]),
                          )); // Show error if the request failed
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: widget.dog.dogID == ""
                              ? Text("Dog added successfully")
                              : Text("Dog updated successfully"),
                        )); // Show success message
                        if (widget.dog.dogID == "") {
                          context.pop(); // Pop the screen if a new dog is added
                          setState(
                              () {}); // Refresh the state to show the new dog in the list
                        }
                        widget
                            .onEdit(); // Call the onEdit callback to refresh the dog list in the homescreen
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
                        minimumSize:
                            WidgetStateProperty.all(Size(double.infinity, 50)),
                        padding: WidgetStateProperty.all(EdgeInsets.all(8)),
                      ),
                      child: Text(
                        widget.dog.dogID == "" ? "ADD DOG" : "SAVE CHANGES",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ), // Space between save and delete buttons
                  if (widget.dog.dogID !=
                      "") // Show delete button only if editing an existing dog
                    ElevatedButton(
                      onPressed: () => _showDogDeleteConfirmDialog(context),
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
                        "DELETE DOG",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
