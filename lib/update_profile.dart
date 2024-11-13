import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  bool isEditing = false;
  Map<String, dynamic> userInfo = {};
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        userInfo = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      });

      // Initialize controllers with fetched data or default values
      controllers['name'] = TextEditingController(text: userInfo['name'] ?? '');
      controllers['age'] = TextEditingController(text: userInfo['age']?.toString() ?? '');
      controllers['occupation'] = TextEditingController(text: userInfo['occupation'] ?? '');
      controllers['savings'] = TextEditingController(text: userInfo['savings']?.toString() ?? '');
      controllers['phone'] = TextEditingController(text: userInfo['phone'] ?? '');
      controllers['sex'] = TextEditingController(text: userInfo['sex'] ?? '');
    }
  }

  void toggleEditing() async {
    if (isEditing) {
      // Save changes to Firebase when toggling off edit mode
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': controllers['name']?.text,
          'age': int.tryParse(controllers['age']?.text ?? ''),
          'occupation': controllers['occupation']?.text,
          'savings': double.tryParse(controllers['savings']?.text ?? ''),
          'phone': controllers['phone']?.text,
          'sex': controllers['sex']?.text,
        }, SetOptions(merge: true));
        
        // Refresh the user information to reflect changes
        await fetchUserInfo();
      }
    }

    setState(() {
      isEditing = !isEditing;
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: toggleEditing,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? buildEditForm() : buildProfileView(),
      ),
    );
  }

  Widget buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        profileField('Name', userInfo['name'] ?? 'Not Found'),
        profileField('Age', userInfo['age']?.toString() ?? 'Not Found'),
        profileField('Occupation', userInfo['occupation'] ?? 'Not Found'),
        profileField('Savings', userInfo['savings']?.toString() ?? 'Not Found'),
        profileField('Phone', userInfo['phone'] ?? 'Not Found'),
        profileField('Sex', userInfo['sex'] ?? 'Not Found'),
      ],
    );
  }

  Widget profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editField('Name', controllers['name']!),
        editField('Age', controllers['age']!),
        editField('Occupation', controllers['occupation']!),
        editField('Savings', controllers['savings']!),
        editField('Phone', controllers['phone']!),
        editField('Sex', controllers['sex']!),
      ],
    );
  }

  Widget editField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: label == 'Age' || label == 'Savings' ? TextInputType.number : TextInputType.text,
      ),
    );
  }
}
