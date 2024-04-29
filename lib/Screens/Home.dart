import 'package:basic_crud_flutter/Screens/Allmountains.dart';
import 'package:basic_crud_flutter/Screens/checklist_page.dart';
import 'package:basic_crud_flutter/Screens/trek_community.dart';
import 'package:basic_crud_flutter/Widgets/NavBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';


import 'MountainSearchScreen.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double screenHeight = 0;
  double screenWidth = 0;
  bool startAnimation = false;


  TextEditingController _locationController = TextEditingController();
  List<String>LikedHills = [];

  void updateLikedHills(List<String> updatedLikedHills) {
    setState(() {
      LikedHills = updatedLikedHills;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        startAnimation = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 260,
              color: Color(0xFFF8F6E3),
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60,),
                  Padding(
                    padding: const EdgeInsets.only(right: 110),
                    child: Container(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Hi ",
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors
                                    .black, // You can change color here
                              ),
                            ),
                            TextSpan(
                              text: "Anirban!",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue, // You can change color here
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5,),
                  Padding(
                    padding: const EdgeInsets.only(right: 130),
                    child: Container(
                      child: Text(
                        "Let's discover a new trek",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600]
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25,),
                  Container(

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(color: Colors.black),
                    ),
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: "Search",
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 5),
                        border: InputBorder.none,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    HillStationSearchPage(
                                      location: _locationController.text,)));
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(color: Colors.transparent)),
                            ),
                            child: Icon(Icons.search, color: Colors.purple),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Adding padding between the container and the screen
                ],
              ),
            ),
            SizedBox(height: 30,),
            Container(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => allmountainsview(
                              likedHills: LikedHills,
                              updateLikedHills: updateLikedHills)));
                    },
                    child: Stack(
                      children: [
                        Container(
                          height: 200,
                          width: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            border: Border.all(color: Colors.black),
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/Images/AdobeStock_78089331_Preview.jpeg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            'Explore Mountains Here',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> Checklist()));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 200,
                          width: 180,
                          color: Color(0xFFDA0C81),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 38,
                                left: 15,
                                child: Text("Hill \nStation \nCheckList",
                                style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold
                                ),),
                              ),
                              Positioned(
                                top: 27,
                                right: 15,
                                child: Image.asset("assets/Icons/checklist.png",height: 50,),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrekkerBlogScreen(),
                          ),
                        );

                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 200,
                          width: 180,
                          color: Color(0xFF4CCD99),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 40,
                                left: 15,
                                child: Text(
                                  "Trek \nCommunity",
                                  style:GoogleFonts.montserrat(
                                  fontSize: 22,
                                  color: Colors.white,
                                      fontWeight: FontWeight.bold
                                ),
                                ),
                              ),
                              Positioned(
                                top: 22,
                                right: 12,
                                child: Image.asset("assets/Icons/icons8-community-96.png", height: 65),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                  ],
                )
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(

          child: BottomNavigationBar(
            backgroundColor: Color(0xFF97E7E1),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home, color: Colors.purpleAccent,),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined,color: Colors.black,),
                label: 'Menu',
              ),
            ],
            onTap: (int index) {
              if (index == 1) {
                // When profile icon is tapped, open the drawer
                _scaffoldKey.currentState!.openDrawer();
              }
            },
            // Define the selected and unselected label styles
            // Change color to your desired color
            selectedItemColor: Colors.purpleAccent,
            unselectedItemColor: Colors.purpleAccent,
          )

        ),
      ),

    );
  }



}





