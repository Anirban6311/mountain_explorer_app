import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:basic_crud_flutter/Services/Mountainjson.dart';


class allmountainsview extends StatefulWidget {
  const allmountainsview({super.key});

  @override
  State<allmountainsview> createState() => _allmountainsviewState();
}


class _allmountainsviewState extends State<allmountainsview> {
  late List<Mountain> mountains=[];

  @override
  void initState() {
    super.initState();
    loadMountains(); // Call the loadMountains function when the widget is initialized
  }

  Future<void> loadMountains()  async{
    String jsonString= await rootBundle.loadString('assets/hill_station.json');
    List<dynamic> mountainData=jsonDecode(jsonString);

    setState(() {
      mountains=mountainData.map((json) => Mountain.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Widget buildImage(Mountain mountain, int index)=> ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        Expanded(
          child: Container(
            child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.network(
                  mountain.imageUrl,
                  fit: BoxFit.cover,
                )
            ),
          ),
        ),
        Positioned(
          top: 30, // Adjust the position as needed
          left: 30, // Adjust the position as needed
          child: Text(
            mountain.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}




