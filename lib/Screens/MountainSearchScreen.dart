import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart' show rootBundle;

class HillStationSearchPage extends StatefulWidget {
  final String location;

  HillStationSearchPage({required this.location});

  @override
  State<HillStationSearchPage> createState() => _HillStationSearchPageState();
}

class _HillStationSearchPageState extends State<HillStationSearchPage> {
  List<String> _hillStationNames = [];
  List<String> mountainNames=[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchHillStations(widget.location);
  }


  Future<void> _searchHillStations(String location) async {
    //url from nominatim api for geocoding
    String uri =
        "https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1";

    try {
      //getting the response from the url(http.get(uri))
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        //if the response is attained
        //get the data from the api(json body)
        var data = json.decode(response.body);
        double latitude = double.parse(data[0]['lat']);
        double longitude = double.parse(data[0]['lon']); //getting the latitude values fron string to double

        await _fetchNearbyHillStations(latitude, longitude);
      } else {
        throw Exception("Failed to load location data");
      }
    } catch (e) {
      print("Error $e");
    }
  }

  Future<void> _fetchNearbyHillStations(
      double latitude, double longitude) async {
    List<String> popularHillStations = [
      'Darjeeling',
      'Kasauli',
      'Kasol',
      'Srinagar',
      'Shimla',
      'Manali',
      'Mussoorie',
      'Nainital',
      'Ooty',
      'Munnar',
      'Kodaikanal',
      'Gulmarg',
      'Gangtok',
      'Leh',
      'Auli',
      'Coorg',
      'Kullu',
      'Ladakh',
      'Almora',
      'Matheran',
      'Mount Abu',
      'Pahalgam',
      'Kalimpong',
      'Nandi Hills',
      'Rishikesh',
      'Lansdowne',
      'Yercaud',
      'Chamba',
      'Patnitop',
      'Wayanad',
      'Tawang',
      'Kufri',
      'Mashobra',
      'Coonoor',
      'Pelling',
      'Narkanda',
      'Dharamshala',
      'Lonavala',
      'Gulaba',
      'Horsley Hills',
      'Chikmagalur',
      'Dhanaulti',
      'Kanatal',
      'Panchgani',
      'Nagarkot',
      'Tirthan Valley',
    ];
    try {
      Set<String> hillStationNames = Set();

      for (var station in popularHillStations) {
        String url =
            'https://overpass-api.de/api/interpreter?data=[out:json];(node(around:300000,$latitude,$longitude)["name"="$station"];);out;'; // radius reduced to 300 kilometers

        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          for (var result in data['elements']) {
            var name = result['tags']['name'];
            if (name != null && name == station) {
              hillStationNames.add(name);
              break; // Once found, no need to continue searching
            }
          }
        } else {
          throw Exception('Failed to load nearby hill stations');
        }
      }

      setState(() {
        _hillStationNames = hillStationNames.toList(); // Convert Set to List
        _isLoading = false;
      });
    }
    catch(e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hill Station Search'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.0),
            Text(
              'Nearby Hill Stations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60.0),
            _isLoading
                ? Lottie.asset('assets/Animations/bus_animation.json')
                : Expanded(
              child: ListView.builder(
                itemCount: _hillStationNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_hillStationNames[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
