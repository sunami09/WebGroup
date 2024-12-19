import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _errorMessage = '';
  bool _isLengthValid = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasSpecialCharacter = false;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  void _validatePassword(String password) {
    setState(() {
      _isLengthValid = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasSpecialCharacter = password.contains(RegExp(r'[!@#\$%^&*(),.?\":{}|<>]'));
    });
  }

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      User? user = _auth.currentUser;

      // Reauthenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(_newPasswordController.text);

      setState(() {
        _isLoading = false;
        _errorMessage = 'Password changed successfully!';
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${error.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              onChanged: _validatePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildPasswordCriteria(),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(
                  color: _errorMessage.contains('successfully') ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
  onPressed: _isLengthValid &&
          _hasUppercase &&
          _hasLowercase &&
          _hasSpecialCharacter
      ? _changePassword
      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Button color
                foregroundColor: Colors.black, // Text color for better contrast
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCriteria('At least 8 characters', _isLengthValid),
        _buildCriteria('At least one uppercase letter', _hasUppercase),
        _buildCriteria('At least one lowercase letter', _hasLowercase),
        _buildCriteria('At least one special character', _hasSpecialCharacter),
      ],
    );
  }

  Widget _buildCriteria(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check : Icons.close,
          color: isValid ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }
}
