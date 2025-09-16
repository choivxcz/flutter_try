import 'package:flutter/material.dart';
import 'package:flutter_try/widget_tree.dart';
import 'package:flutter_try/widgets/navbar_widget.dart';

class AnimatedTextBox extends StatefulWidget { 
  const AnimatedTextBox({super.key});

  @override
  State<AnimatedTextBox> createState() => _AnimatedTextBoxState();
}

class _AnimatedTextBoxState extends State<AnimatedTextBox> {
  bool _isToggled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Animated Text Box')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isToggled = !_isToggled;
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return WidgetTree();
                  },
                ),
              );
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 500), // how fast animation is
            padding: EdgeInsets.all(_isToggled ? 30 : 15),
            width: _isToggled ? 250 : 150,
            height: _isToggled ? 100 : 60,
            decoration: BoxDecoration(
              color: _isToggled ? Colors.green : Colors.yellowAccent,
              borderRadius: BorderRadius.circular(_isToggled ? 30 : 10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: _isToggled ? 20 : 5,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Tap Me!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavBar(),
    );
  }
}
