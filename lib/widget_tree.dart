import 'package:flutter/material.dart';
import 'package:flutter_try/datas/notifiers.dart';
import 'package:flutter_try/pages/home_page.dart';
import 'package:flutter_try/pages/profile_page.dart';
import 'package:flutter_try/widgets/drawer.dart';
import 'package:flutter_try/widgets/navbar_widget.dart';

List<Widget> pages = [
  HomePage(),
  ProfilePage(),
];
class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('First App'),
        centerTitle: true,
        backgroundColor: Color(0xFFCFC7FA),
      ),
      body: ValueListenableBuilder(
        valueListenable: currentSelectedPage,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        }
      ),
      drawer: DrawerWidget(),
      bottomNavigationBar: NavBar(),
    );
  }
}