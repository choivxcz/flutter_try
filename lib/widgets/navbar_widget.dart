import 'package:flutter/material.dart';
import 'package:flutter_try/datas/notifiers.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentSelectedPage,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          backgroundColor: Color(0xFFCFC7FA),
          indicatorColor: Color(0xFF1F51FF),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onDestinationSelected: (int value){
            currentSelectedPage.value = value;
          },
          selectedIndex: selectedPage,
        );
      },
    );
  }
}
