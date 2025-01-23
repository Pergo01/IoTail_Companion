import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iotail_companion/util/dog.dart';
import 'package:iotail_companion/util/requests.dart' as requests;

class DogScreen extends StatefulWidget {
  final Dog dog;
  final String userID;
  final String ip;
  final String token;
  final VoidCallback onEdit;

  const DogScreen(
      {super.key,
      required this.dog,
      required this.userID,
      required this.ip,
      required this.token,
      required this.onEdit});

  @override
  _DogScreenState createState() => _DogScreenState();
}

class _DogScreenState extends State<DogScreen> {
  Uint8List? _pickedImage;
  late String _name;
  late String _breed;
  late int _age;
  late String _sex;
  late String _size;
  late double _weight;
  late String _coatType;
  late List<String> _allergies;
  String? _imagePath;
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  final ExpansionTileController _sexController = ExpansionTileController();
  final ExpansionTileController _sizeController = ExpansionTileController();
  late final TextEditingController _weightController;
  final ExpansionTileController _coatTypeController = ExpansionTileController();
  late final TextEditingController _allergiesController;

  @override
  void initState() {
    super.initState();
    _pickedImage = widget.dog.picture;
    _name = widget.dog.name;
    _nameController =
        TextEditingController(text: widget.dog.name != "" ? _name : null);
    _breed = widget.dog.breed;
    _breedController =
        TextEditingController(text: widget.dog.breed != "" ? _breed : null);
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
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
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
                        _showDogPictureDeleteConfirmDialog(context);
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

  void _showDogPictureDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          title: Text('Delete Dog image'),
          content: Text('Are you sure you want to delete the dog\'s image?'),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop();
                Map<String, dynamic> message = await requests.deleteDogPicture(
                    widget.ip, widget.token, widget.userID, widget.dog.dogID);
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Dog image deleted successfully"),
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
                context.pop();
                Map<String, dynamic> message = await requests.deleteDog(
                    widget.ip, widget.token, widget.userID, widget.dog.dogID);
                if (message["message"].contains("Failed")) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(message["message"]),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Dog deleted successfully"),
                  ));
                  context.pop();
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
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
                              ? Image.asset("assets/default_cane.jpeg",
                                  height: 150, width: 150, fit: BoxFit.fill)
                              : Image.memory(_pickedImage!,
                                  height: 150, width: 150, fit: BoxFit.fill)),
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
                    child: TextField(
                      controller: _breedController,
                      onChanged: (value) {
                        _breed = value;
                      },
                      decoration: InputDecoration(
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
                        hintText: "Your dog's breed",
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
                  ElevatedButton(
                    onPressed: () async {
                      Map tmp = {
                        "dogID": widget.dog.dogID,
                        "name": _name,
                        "breed": _breed,
                        "age": _age,
                        "sex": _sex == "Male" ? 0 : 1,
                        "size": _size,
                        "weight": _weight,
                        "coatType": _coatType,
                        "allergies": _allergies,
                        "Picture": _imagePath,
                      };
                      final response = widget.dog.dogID == ""
                          ? await requests.addDog(
                              widget.ip, widget.token, widget.userID, tmp)
                          : await requests.editDog(
                              widget.ip, widget.token, widget.userID, tmp);
                      if (response["message"].toString().contains("Failed")) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(response["message"]),
                        ));
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: widget.dog.dogID == ""
                            ? Text("Dog added successfully")
                            : Text("Dog updated successfully"),
                      ));
                      if (widget.dog.dogID == "") {
                        context.pop();
                        setState(() {});
                      }
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
                      minimumSize:
                          WidgetStateProperty.all(Size(double.infinity, 50)),
                      padding: WidgetStateProperty.all(EdgeInsets.all(8)),
                    ),
                    child: Text(
                      widget.dog.dogID == "" ? "ADD DOG" : "SAVE CHANGES",
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  if (widget.dog.dogID != "")
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
