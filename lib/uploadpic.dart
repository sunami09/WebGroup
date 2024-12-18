import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pass BuildContext to access the widget tree
Future<void> pickAndUploadPhoto(BuildContext context, Function setState, Map<String, dynamic> userInfo) async {
  final ImagePicker picker = ImagePicker();

  final XFile? image = await showDialog<XFile>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context, await picker.pickImage(source: ImageSource.camera));
            },
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery));
            },
            child: const Text("Gallery"),
          ),
        ],
      );
    },
  );

  if (image != null) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profilePics/${user.uid}.jpg');

        await storageRef.putFile(File(image.path));

        String downloadUrl = await storageRef.getDownloadURL();
        print("Download URL: $downloadUrl");

        // Use .set() instead of .update() to ensure document creation
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profilePic': downloadUrl,
        }, SetOptions(merge: true)).then((_) {
          print("Firestore successfully updated with profilePic.");
        }).catchError((error) {
          print("Error updating Firestore: $error");
        });

        // Update the UI
        setState(() {
          userInfo['profilePic'] = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      } catch (e) {
        print("Error during upload: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload photo: $e")),
        );
      }
    } else {
      print("User is not authenticated.");
    }
  } else {
    print("No image selected.");
  }
}
