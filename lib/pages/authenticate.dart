import 'package:flutter/material.dart';
import 'package:flutter_try/auth.dart';
import 'package:flutter_try/pages/login_page.dart';
import 'package:flutter_try/widget_tree.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _Authenticate();
}

class _Authenticate extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData){
          return WidgetTree();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}