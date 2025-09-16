import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_try/pages/Authenticate.dart';
import 'package:flutter_try/pages/signin_page.dart';
import '../auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email and password must not be blank.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await Auth().signInWithEmailPassword(email: email, password: password);
      setState(() {
        errorMessage = '';
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Authenticate()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'An error occurred';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _title() {
    return const Text('First App');
  }

  Widget _entryFieldEmail(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: title,
        icon: const Icon(Icons.email),
        iconColor: const Color(0xFFCFC7FA),
        filled: true,
        fillColor: const Color(0xFFCFC7FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFCED9ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFCED9ED), width: 8),
        ),
      ),
    );
  }

  Widget _entryFieldPassword(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: title,
        icon: const Icon(Icons.lock),
        iconColor: const Color(0xFFCFC7FA),
        filled: true,
        fillColor: const Color(0xFFCFC7FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCED9ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(width: 8, color: Color(0xFFCED9ED)),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return GestureDetector(
      onTap: signInWithEmailAndPassword,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCED9ED),
          borderRadius: BorderRadius.circular(14.0),
        ),
        padding: const EdgeInsets.all(15),
        child: const Center(
          child: Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF1F51FF),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _createButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const SigninPage();
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCED9ED),
          borderRadius: BorderRadius.circular(14.0),
        ),
        padding: const EdgeInsets.all(15),
        child: const Center(
          child: Text(
            'Create an Account',
            style: TextStyle(
              color: Color(0xFF1F51FF),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
        centerTitle: true,
        backgroundColor: const Color(0xFFCFC7FA),
      ),
      body: Container(
        padding: const EdgeInsets.all(45),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _entryFieldEmail('email', _controllerEmail),
                const SizedBox(height: 10.0),
                _entryFieldPassword('password', _controllerPassword),
                const SizedBox(height: 20.0),
                _submitButton(context),
                const SizedBox(height: 20.0),
                _createButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
