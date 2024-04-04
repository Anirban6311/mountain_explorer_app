import 'package:basic_crud_flutter/Screens/Home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScreenOne extends StatelessWidget {
  const ScreenOne({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Images/mountain1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 150,),
              Padding(
                padding: const EdgeInsets.only(left: 30,bottom: 20),
                child: Text(
                  'Mountains Calling?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Padding(

                padding: const EdgeInsets.only(left: 30, bottom: 20),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.amberAccent, // Change the color here
                    ),
                    fixedSize: MaterialStateProperty.all<Size>(
                      Size(330, 50), // Change the height and width here
                    ),
                    iconSize: MaterialStateProperty.all<double>(
                      40, // Change the icon size here
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(context, SlidePageRouteBuilder(page: HomeScreen()));
                  },
                  child: Row(
                    children: [
                      Text("Start Your Journey Here!",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black
                      ),),
                      Icon(Icons.arrow_circle_right)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class SlidePageRouteBuilder extends PageRouteBuilder {
  final Widget page;

  SlidePageRouteBuilder({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(1.0, 0.0);
      var end = Offset.zero;
      var curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
