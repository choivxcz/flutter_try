import 'package:flutter/material.dart';
import 'package:flutter_try/pages/login_page.dart';
import 'package:flutter_try/pages/signin_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Widget _title() {
    return Text('Tracker');
  }

  Widget _login(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoginPage();
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFCED9ED),
          borderRadius: BorderRadius.circular(14),
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

  Widget _createAccount(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return SigninPage();
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFCED9ED),
          borderRadius: BorderRadius.circular(14),
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

  Widget _header() {
    return Text(
      'Welcome!',
      style: TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurpleAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
        centerTitle: true,
        backgroundColor: Color(0xFFCFC7FA),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(45),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _header(),
            SizedBox(height: 20),
            _login(context),
            SizedBox(height: 20),
            _createAccount(context),
          ],
        ),
      ),
    );
  }
}
