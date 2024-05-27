import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class BlogDetailScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController commentController = TextEditingController();

  final String imageUrl;
  final String title;
  final String description;
  final String pId;

  BlogDetailScreen({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.pId,
  });

  void addComment(BuildContext context, String commentText) async {
    if (commentText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(pId)
        .collection("comments")
        .add({
      "CommentText": commentText,
      "CommentedBy": currentUser.displayName ?? 'Anonymous',
      "CommentTime": Timestamp.now(),
    });

    commentController.clear();
    Navigator.pop(context);  // Close the dialog after adding the comment
  }

  void showCommentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Comment"),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: "Write a comment",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              addComment(context, commentController.text);
            },
            child: Text("Post"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) =>
                  Image.asset('Images/drawer_mountain.jpg'),
              errorWidget: (context, url, error) => Icon(Icons.error),
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 1.0,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                                // Add more text or widgets as needed
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.comment),
                            onPressed: () => showCommentDialog(context),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30,),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("Posts")
                          .doc(pId)
                          .collection("comments")
                          .orderBy("CommentTime", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            DateTime commentTime = (comment["CommentTime"] as Timestamp).toDate();
                            String formattedDate = DateFormat('dd/MM/yyyy').format(commentTime);
                            return ListTile(
                              title: Text(comment["CommentedBy"]),
                              subtitle: Text(comment["CommentText"]),
                              trailing: Text(
                                formattedDate,
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
