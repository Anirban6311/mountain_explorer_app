import 'dart:convert';
import 'package:basic_crud_flutter/Services/weather.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/Mountainjson.dart';
import 'package:http/http.dart' as http;
import 'package:basic_crud_flutter/models/weatherModel.dart';

class allmountainsview extends StatefulWidget {
  final List<String> likedHills;
  final Function(List<String>) updateLikedHills;

  allmountainsview({Key? key, required this.likedHills, required this.updateLikedHills});




  @override
  State<allmountainsview> createState() => _allmountainsviewState();
}

class _allmountainsviewState extends State<allmountainsview> {
  late List<Mountain> mountains=[];
  late List<bool> isPressed=[];
  final _weatherService= WeatherService("1b330849ea15fcd2609c5a8197a98cda");
  Weather? weather;
  _fetchWeather() async{
    try{
      final weather=await _weatherService.getWeather("cityName");
      setState(() {
        _weather=weather;
      });
    }
    catch(e){
      print(e);
    }
  }



  @override
  void initState() {
    super.initState();
    loadMountains(); // Call the loadMountains function when the widget is initialized
  }




  Future<void> loadMountains() async {
    try {
      String jsonString = await rootBundle.loadString('assets/hill_station.json');
      List<dynamic> mountainData = jsonDecode(jsonString);

      // Fetch liked mountains from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('liked_mountains').doc('liked').get();
      List<dynamic>? likedMountains = (doc.data() as Map<String, dynamic>?)?['likedMountains'] as List<dynamic>?;

      setState(() {
        mountains = mountainData.map((json) => Mountain.fromJson(json)).toList();
        isPressed = List<bool>.filled(mountains.length, false);

        // Update isPressed based on liked mountains fetched from Firestore
        for (int i = 0; i < mountains.length; i++) {
          if (likedMountains != null && likedMountains.contains(mountains[i].name)) {
            isPressed[i] = true;
          }
        }
      });
    } catch (error) {
      // Handle any errors that occur during data loading
      print('Error loading mountains: $error');
      // You can display an error message to the user or retry loading data
    }
  }




  @override
  Widget build(BuildContext context) {
    if (mountains == null || isPressed == null) {
      // Show circular loader while data is loading
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // or any other loading indicator
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // Example start color
              Colors.blueAccent, // Example end color
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CarouselSlider.builder(
                itemCount: mountains.length,
                itemBuilder: (context, index, realIndex) {
                  Mountain mountain = mountains[index];
                  return buildImage(mountain, index);
                },
                options: CarouselOptions(
                  height: 550,
                  enlargeCenterPage: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildImage(Mountain mountain, int index) {


    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onDoubleTap: () {
          setState(() {
            isPressed[index] = !isPressed[index];
            if (isPressed[index]) {
              // Update likedHills locally
              widget.updateLikedHills([...widget.likedHills, mountain.name]);
              // Update likedMountains in Firestore
              FirebaseFirestore.instance.collection('liked_mountains').doc('liked').update({
                'likedMountains': FieldValue.arrayUnion([mountain.name])
              });
            } else {
              // Remove mountain from likedHills
              widget.updateLikedHills(widget.likedHills.where((element) => element != mountain.name).toList());
              // Update likedMountains in Firestore
              FirebaseFirestore.instance.collection('liked_mountains').doc('liked').update({
                'likedMountains': FieldValue.arrayRemove([mountain.name])
              });
            }
          });
        },
        onTap: () {},
        child: Stack(
          children: [
            Container(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.network(
                  mountain.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Text(
                mountain.name,
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 40,
              child: Icon(
                Icons.add,
              ),
            ),
            Positioned(
              bottom: 38,
              left: 140,
              child: Icon(
                Icons.favorite,
                color: isPressed[index] ? Colors.pinkAccent : Colors.white,
                // Toggle color based on favorite status
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }



}
