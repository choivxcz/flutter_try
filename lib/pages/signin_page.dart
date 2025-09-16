import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try/auth.dart';
import 'package:flutter_try/pages/login_page.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  String? errorMessage = '';

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> createUserWithEmailAndPassword() async {
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
      await Auth().createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      setState(() {
        errorMessage = '';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Error creating account.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  Widget _entryFieldEmail(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: title,
        icon: const Icon(Icons.mail),
        iconColor: const Color(0xFFCFC7FA),
        filled: true,
        fillColor: const Color(0xFFCFC7FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFCED9ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFCED9ED), width: 8),
        ),
      ),
    );
  }

  Widget _createButton() {
    return GestureDetector(
      onTap: () async {
        await createUserWithEmailAndPassword();
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCED9ED),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(15),
        child: const Center(
          child: Text(
            'Create Account',
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
        title: const Text('Tracker'),
        centerTitle: true,
        backgroundColor: const Color(0xFFCFC7FA),
      ),
      body: Container(
        padding: const EdgeInsets.all(45),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _entryFieldEmail('Email', _controllerEmail),
              const SizedBox(height: 20.0),
              _entryFieldPassword('Password', _controllerPassword),
              const SizedBox(height: 20.0),
              _createButton(),
            ],
          ),
        ),
      ),
    );
  }
}

