import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:flutter_try/final_project/services/shared_pref.dart';
import 'package:flutter_try/final_project/pages/login_page.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> registration() async {
    if (namecontroller.text.isEmpty ||
        passcontroller.text.isEmpty ||
        mailcontroller.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (passcontroller.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      Map<String, dynamic> userInfoMap = {
        "Name": namecontroller.text,
        "Email": mailcontroller.text,
        "Id": uid,
      };

      await DatabaseMethods().addUserInfo(userInfoMap, uid);
      await SharedpreferenceHelper().saveUserEmail(mailcontroller.text);
      await SharedpreferenceHelper().saveUserName(namecontroller.text);
      await SharedpreferenceHelper().saveUserId(uid);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    namecontroller.dispose();
    passcontroller.dispose();
    mailcontroller.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAD25B),
              Color.fromARGB(255, 228, 214, 158),
              Color(0xFFFFFAF0),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Image(
                      image: AssetImage("assets2/images/PPbr.png"),
                      height: 120,
                      width: 120,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      "Sign Up Account",
                      style: TextStyle(
                        color: Color.fromARGB(221, 255, 255, 255),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      "Enter your personal data to create\nyour account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(136, 0, 0, 0),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFEAD25B)),
                    ),
                    child: TextField(
                      controller: namecontroller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Full Name",
                        hintStyle: TextStyle(
                            color: Color.fromARGB(255, 5, 5, 5), fontSize: 14),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        prefixIcon: Icon(Icons.person_outline,
                            color: Color.fromARGB(255, 8, 8, 8), size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFEAD25B)),
                    ),
                    child: TextField(
                      controller: mailcontroller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Email",
                        hintStyle: TextStyle(
                            color: Color.fromARGB(255, 5, 5, 5), fontSize: 14),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        prefixIcon: Icon(Icons.mail_outline,
                            color: Color.fromARGB(255, 8, 8, 8), size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFEAD25B)),
                    ),
                    child: TextField(
                      controller: passcontroller,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Password",
                        hintStyle: const TextStyle(
                            color: Color.fromARGB(255, 5, 5, 5), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color.fromARGB(255, 10, 10, 10), size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color.fromARGB(255, 7, 7, 7),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFEAD25B)),
                    ),
                    child: TextField(
                      controller: confirmPassController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Confirm Password",
                        hintStyle: const TextStyle(
                            color: Color.fromARGB(255, 5, 5, 5), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color.fromARGB(255, 10, 10, 10), size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color.fromARGB(255, 7, 7, 7),
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAD25B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(color: Colors.black54, fontSize: 15),
                          children: [
                            TextSpan(text: "Already have an Account? "),
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                color: Color(0xFFE5A533),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFE5A533),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}