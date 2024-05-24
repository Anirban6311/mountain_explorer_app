import 'package:basic_crud_flutter/Screens/Community/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


import 'addPost.dart';

class communityHome extends StatefulWidget {
  const communityHome({super.key});

  @override
  State<communityHome> createState() => _communityHomeState();
}

class _communityHomeState extends State<communityHome> {

  final dbRef= FirebaseDatabase.instance.reference().child('Posts');
  FirebaseAuth auth= FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Blogs"),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: (){
               auth.signOut().then((value) {
                 Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginScreen()));
               });
            },
            child: Icon(Icons.logout) ,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20 , horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FirebaseAnimatedList(
                  query: dbRef.child('Post List'),
                  itemBuilder: (BuildContext context, DataSnapshot snapshot,
                      Animation<double> animation, int index) {
                    if (snapshot.value == null) {
                      return const CircularProgressIndicator();
                    } else {
                      final data = snapshot.value as Map<dynamic, dynamic>;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CachedNetworkImage(
                            imageUrl: data['pImage'],
                            placeholder: (context, url) => Image.asset('Images/drawer_mountain.jpg'),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            fadeInDuration: Duration(milliseconds: 500),
                            fit: BoxFit.cover,
                          ),
                          Text(data['pTitle'],),
                          Text(data['pDescription']),
                        ],
                      );
                    }
                  }),
            )
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> AddPost()));

        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }
}
