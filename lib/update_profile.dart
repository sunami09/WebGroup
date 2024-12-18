import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'uploadpic.dart';
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
      controllers['age'] =
          TextEditingController(text: userInfo['age']?.toString() ?? '');
      controllers['occupation'] =
          TextEditingController(text: userInfo['occupation'] ?? '');
      controllers['savings'] =
          TextEditingController(text: userInfo['savings']?.toString() ?? '');
      controllers['phone'] =
          TextEditingController(text: userInfo['phone'] ?? '');
      controllers['sex'] = TextEditingController(text: userInfo['sex'] ?? '');
      controllers['profilePic'] = TextEditingController(
          text: userInfo['profilePic'] ??
              'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg');
    }
  }

  void toggleEditing() async {
    if (isEditing) {
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

        await fetchUserInfo();
      }
    }

    setState(() {
      isEditing = !isEditing;
    });
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? buildEditForm() : buildProfileView(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: toggleEditing,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEditing ? Colors.green : Colors.redAccent,
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          child: Text(
            isEditing ? 'Save Changes' : 'Edit',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget buildProfileView() {
    if (userInfo.isEmpty) {
      return const Center(
        child: Text(
          'Profile not updated, please update it.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: NetworkImage(
            userInfo['profilePic'] ??
                'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        Text(
          userInfo['name'] ?? 'Name Not Found',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        buildProfileCard('Age', userInfo['age']?.toString() ?? 'Not Found'),
        buildProfileCard(
            'Occupation', userInfo['occupation'] ?? 'Not Found'),
        buildProfileCard(
            'Savings', userInfo['savings']?.toString() ?? 'Not Found'),
        buildProfileCard('Phone', userInfo['phone'] ?? 'Not Found'),
        buildProfileCard('Sex', userInfo['sex'] ?? 'Not Found'),
      ],
    );
  }

  Widget buildProfileCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget buildEditForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: NetworkImage(
            controllers['profilePic']!.text,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            pickAndUploadPhoto(context, setState, userInfo);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 40),
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text(
            'Add Photo',
            style: TextStyle(color: Colors.white),
          ),
        ),

        const SizedBox(height: 16),
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
        keyboardType: label == 'Age' || label == 'Savings'
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }
}
