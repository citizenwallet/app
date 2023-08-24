import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

enum ProfileUpdateState {
  idle,
  existing,
  uploading,
  fetching;

  double get progress {
    switch (this) {
      case ProfileUpdateState.idle:
        return 0;
      case ProfileUpdateState.existing:
        return 0.25;
      case ProfileUpdateState.uploading:
        return 0.5;
      case ProfileUpdateState.fetching:
        return 1;
    }
  }
}

class ProfileState with ChangeNotifier {
  String account = '';
  String username = '';
  String name = '';
  String description = '';
  String image = '';
  String imageMedium = '';
  String imageSmall = '';

  bool loading = false;
  bool error = false;

  ProfileUpdateState updateState = ProfileUpdateState.idle;

  // editing
  final TextEditingController usernameController = TextEditingController();
  bool usernameLoading = false;
  bool usernameError = false;

  final TextEditingController nameController = TextEditingController();
  bool nameError = false;

  final TextEditingController descriptionController = TextEditingController();
  String descriptionEdit = '';

  Uint8List? editingImage;
  String? editingImageExt;

  // viewing
  bool viewLoading = false;
  bool viewError = false;
  ProfileV1? viewProfile;

  void resetAll({notify = false}) {
    account = '';
    username = '';
    name = '';
    description = '';
    image = '';
    imageMedium = '';
    imageSmall = '';

    usernameController.text = '';
    usernameLoading = false;
    usernameError = false;

    nameController.text = '';
    nameError = false;

    descriptionController.text = '';
    descriptionEdit = '';

    editingImage = null;

    if (notify) notifyListeners();
  }

  void resetEditForm({notify = false}) {
    usernameController.text = '';
    usernameLoading = false;
    usernameError = false;

    nameController.text = '';
    nameError = false;

    descriptionController.text = '';
    descriptionEdit = '';

    editingImage = null;

    if (notify) notifyListeners();
  }

  void resetViewProfile({notify = false}) {
    viewLoading = false;
    viewError = false;
    viewProfile = null;

    if (notify) notifyListeners();
  }

  void startEdit(Uint8List? image, String? ext) {
    usernameController.text = username;
    nameController.text = name;
    descriptionController.text = description;
    descriptionEdit = description;

    editingImage = image;
    editingImageExt = ext;

    notifyListeners();
  }

  void set({
    required String account,
    required String username,
    required String name,
    required String description,
    required String image,
    required String imageMedium,
    required String imageSmall,
  }) {
    this.account = account;
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

  void setProfileExisting() {
    loading = true;
    error = false;

    updateState = ProfileUpdateState.existing;

    notifyListeners();
  }

  void setProfileUploading() {
    loading = true;
    error = false;

    updateState = ProfileUpdateState.uploading;

    notifyListeners();
  }

  void setProfileFetching() {
    loading = true;
    error = false;

    updateState = ProfileUpdateState.fetching;

    notifyListeners();
  }

  void setProfileSuccess({
    required String account,
    required String username,
    required String name,
    required String description,
    required String image,
    required String imageMedium,
    required String imageSmall,
  }) {
    this.account = account;
    this.username = username;
    this.name = name;
    this.description = description;
    this.image = image;
    this.imageMedium = imageMedium;
    this.imageSmall = imageSmall;

    loading = false;
    error = false;

    updateState = ProfileUpdateState.idle;

    notifyListeners();
  }

  void setProfileNoChangeSuccess() {
    loading = false;
    error = false;

    updateState = ProfileUpdateState.idle;

    notifyListeners();
  }

  void setProfileError() {
    loading = false;
    error = true;

    updateState = ProfileUpdateState.idle;

    notifyListeners();
  }

  void setEditImage(Uint8List image, String ext) {
    editingImage = image;
    editingImageExt = ext;

    notifyListeners();
  }

  void setUsernameRequest() {
    usernameLoading = true;

    notifyListeners();
  }

  void setUsernameSuccess() {
    usernameLoading = false;
    usernameError = false;

    notifyListeners();
  }

  void setUsernameError() {
    usernameLoading = false;
    usernameError = true;

    notifyListeners();
  }

  void setNameError(bool err) {
    nameError = err;

    notifyListeners();
  }

  void setDescriptionText(String desc) {
    descriptionEdit = desc;

    notifyListeners();
  }

  void viewProfileRequest() {
    viewLoading = true;
    viewError = false;

    notifyListeners();
  }

  void viewProfileSuccess(ProfileV1 profile) {
    viewProfile = profile;
    viewLoading = false;
    viewError = false;

    notifyListeners();
  }

  void setViewProfileNoChangeSuccess() {
    viewLoading = false;
    viewError = false;

    notifyListeners();
  }

  void viewProfileError() {
    viewLoading = false;
    viewError = true;

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
