import 'package:flutter/material.dart';
import 'package:flutter_try/pages/login_page.dart';
import 'package:flutter_try/pages/nav_profile_page.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(color: Color(0xFFCFC7FA)),
            child: Center(
              child: Text('Expense Tracker', style: TextStyle(fontSize: 30)),
            ),
          ),
          SizedBox(height: 10,),
          ListTile(
            leading: Icon(Icons.person),
            iconColor: Color(0xFFCFC7FA),
            title: Text(
              'Profile',
              style: TextStyle(color: Colors.blueAccent, fontSize: 25),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return NavProfilePage();
                  },
                ),
              );
            },
          ),
          SizedBox(height: 35,),
          ListTile(
            leading: Icon(Icons.logout),
            iconColor: Color(0xFFCFC7FA),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.blueAccent, fontSize: 25),
            ),
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
          ),
        ],
      ),
    );
  }
}
