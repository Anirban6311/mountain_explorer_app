import 'package:basic_crud_flutter/Screens/Allmountains.dart';
import 'package:flutter/material.dart';

import 'MountainSearchScreen.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();



}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool startAnimation = false;

  TextEditingController _locationController= TextEditingController();
  List<String>LikedHills=[];
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
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 260,
              color: Color(0xFFE6E6FA),
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
                                color: Colors.black, // You can change color here
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 5),
                        border: InputBorder.none,
                        suffixIcon: GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HillStationSearchPage(location: _locationController.text,)));
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.transparent)),
                            ),
                            child: Icon(Icons.search, color: Colors.purple),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Adding padding between the container and the screen
                ],
              ),
            ),
            SizedBox(height: 40,),
            Container(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>allmountainsview(likedHills: LikedHills, updateLikedHills: updateLikedHills)));
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
                              image: AssetImage('assets/Images/AdobeStock_78089331_Preview.jpeg'),
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
                  SizedBox(height: 20,),
                  Container(
                    child: Column(
                      children: [
                        Text("Liked Hill Stations"),
                        Container(
                          height: 200, // Adjust the height as needed
                          child: ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: LikedHills.length,
                            itemBuilder: (context, index) {
                              return item(index);
                            },
                          ),
                        ),
                      ],
                    ),
                  )///for the history
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      
    );
  }

  Widget item(int index) {
    return AnimatedContainer(
      height: 55,
      width: screenWidth,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues(startAnimation ? 0 : screenWidth, 0, 0),
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth / 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${index + 1}. ${LikedHills[index]}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

        ],
      ),
    );
  }

}
  



