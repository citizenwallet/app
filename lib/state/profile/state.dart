import 'package:flutter/cupertino.dart';

class ProfileState with ChangeNotifier {
  String address = '';
  String username = '';
  String name = '';
  String description = '';
  String image = '';
  String imageMedium = '';
  String imageSmall = '';

  // editing
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String editingImage = '';

  bool loading = false;
  bool error = false;

  void reset({notify = false}) {
    address = '';
    username = '';
    name = '';
    description = '';
    image = '';
    imageMedium = '';
    imageSmall = '';

    usernameController.text = '';
    nameController.text = '';
    descriptionController.text = '';

    if (notify) notifyListeners();
  }

  void set({
    required String address,
    required String username,
    required String name,
    required String description,
    required String image,
    required String imageMedium,
    required String imageSmall,
  }) {
    this.address = address;
    this.username = username;
    this.name = name;
    this.description = description;
    this.image = image;
    this.imageMedium = imageMedium;
    this.imageSmall = imageSmall;

    notifyListeners();
  }

  void setProfileRequest() {
    loading = true;
    error = false;

    notifyListeners();
  }

  void setProfileSuccess({
    required String address,
    required String username,
    required String name,
    required String description,
    required String image,
    required String imageMedium,
    required String imageSmall,
  }) {
    this.address = address;
    this.username = username;
    this.name = name;
    this.description = description;
    this.image = image;
    this.imageMedium = imageMedium;
    this.imageSmall = imageSmall;

    loading = false;
    error = false;

    notifyListeners();
  }

  void setProfileError() {
    loading = false;
    error = true;

    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    descriptionController.dispose();

    super.dispose();
  }
}
