import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TrekkerBlogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trekker Community'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('community_posts')
            .doc('posts')
            .collection('posts')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot post = snapshot.data!.docs[index];
                String postId = post.id; // Get the post ID from the document
                return TrekkerBlogPostCard(
                  post: TrekkerBlogPost.fromFirestore(post),
                  postId: postId,
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBlogScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TrekkerBlogPostCard extends StatelessWidget {
  final TrekkerBlogPost post;
  final String postId;

  TrekkerBlogPostCard({required this.post, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(post.author),
                SizedBox(height: 8.0),
                Text(post.content),
                SizedBox(height: 8.0),
                // Display images
                if (post.images != null && post.images!.isNotEmpty)
                  Column(
                    children: post.images!.map((imageUrl) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.network(
                          imageUrl,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  // Handle like functionality
                },
                icon: Icon(Icons.thumb_up),
              ),
              IconButton(
                onPressed: () {
                  // Handle comment functionality
                },
                icon: Icon(Icons.comment),
              ),
              IconButton(
                onPressed: () => _deletePost(context), // Call delete function
                icon: Icon(Icons.delete), // Delete icon
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc('posts')
          .collection('posts')
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Post deleted successfully'),
      ));
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred while deleting the post'),
      ));
    }
  }
}


class TrekkerBlogPost {
  final String title;
  final String author;
  final String date;
  final String content;
  final List<String>? images; // Add images field

  TrekkerBlogPost({
    required this.title,
    required this.author,
    required this.date,
    required this.content,
    this.images, // Update constructor
  });

  factory TrekkerBlogPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<String>? images = List<String>.from(data['images'] ?? []); // Parse images
    return TrekkerBlogPost(
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      date: data['date'] ?? '',
      content: data['content'] ?? '',
      images: images, // Assign parsed images
    );
  }
}

class CreateBlogScreen extends StatefulWidget {
  @override
  _CreateBlogScreenState createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  List<String> imageUrls = [];
  String imageUrl='';

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        // Upload the selected image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(File(pickedFile.path));

        // Get the download URL of the uploaded image
        final String imageUrl = await storageRef.getDownloadURL();

        // Print the URL
        print('Image URL: $imageUrl');

        // Store the URL of the selected image
        setState(() {
          imageUrls.add(imageUrl);
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }


  void _createPost(BuildContext context) async {
    try {
      final List<String> imageUrlStrings = []; // List to store image URLs as strings
      for (final imageUrl in imageUrls) {
        // Add each image URL as a string to the list
        imageUrlStrings.add(imageUrl.toString());
      }

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc('posts')
          .collection('posts')
          .add({
        'title': titleController.text,
        'author': authorController.text,
        'date': DateTime.now().toString(),
        'content': contentController.text,
        'images': imageUrlStrings, // Store image URLs as strings
      });
      Navigator.pop(context);
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Blog Post'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(
                labelText: 'Author',
              ),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Content',
              ),
              maxLines: null,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async{

                //image is picked
                ImagePicker imagePicker = ImagePicker();
                XFile? file =
                await imagePicker.pickImage(source: ImageSource.camera);
                print('${file?.path}');

                if (file == null) return;
                //Import dart:core
                String uniqueFileName =
                DateTime.now().millisecondsSinceEpoch.toString();

                /*Step 2: Upload to Firebase storage*/
                //Install firebase_storage
                //Import the library

                //Get a reference to storage root
                Reference referenceRoot = FirebaseStorage.instance.ref();
                Reference referenceDirImages =
                referenceRoot.child('images');

                //Create a reference for the image to be stored
                Reference referenceImageToUpload =
                referenceDirImages.child('name');

                //Handle errors/success
                try {
                  //Store the file
                  await referenceImageToUpload.putFile(File(file!.path));
                  //Success: get the download URL
                  imageUrl = await referenceImageToUpload.getDownloadURL();
                } catch (error) {
                  //Some error occurred
                }


              },
              child: Text('Select Image'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _createPost(context),
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
