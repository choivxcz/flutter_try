import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

 Widget _userId(){
    final user = FirebaseAuth.instance.currentUser;
    return Text(user?.email ?? 'User Email');
  }
  
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null ? Icon(Icons.person) : null,
              ),
            SizedBox (
              height: 20,
            ),
            _userId(),
            Row(
              children: [
                
              ],
            )
          ],
        ),
      ),
    );
  }
}