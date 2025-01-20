import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  static Future<String?> uploadImage(File image, String destination) async {
    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(image);

      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }
}
