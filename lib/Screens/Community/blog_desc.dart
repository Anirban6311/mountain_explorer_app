import 'package:basic_crud_flutter/Screens/Community/profiles/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class BlogDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String pId;
  final List<String> likes;

  BlogDetailScreen({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.pId,
    required this.likes,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
  }

  void toggleLike() async {
    setState(() {
      isLiked = !isLiked;
    });
    DocumentReference postRef = FirebaseFirestore.instance.collection('Posts').doc(widget.pId);

    if (isLiked) {
      // If post is liked, add the email to the likes field
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUser.email])
      });
    } else {
      // If post is unliked, remove the email from the likes field
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUser.email])
      });
    }

    // Update the local likes list to reflect the new state
    setState(() {
      if (isLiked) {
        widget.likes.add(currentUser.email!);
      } else {
        widget.likes.remove(currentUser.email);
      }
    });
  }

  final TextEditingController commentController = TextEditingController();

  void addComment(BuildContext context, String commentText) async {
    if (commentText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("Posts")
        .doc(widget.pId)
        .collection("comments")
        .add({
      "CommentText": commentText,
      "CommentedBy": currentUser.displayName ?? 'Anonymous',
      "CommentTime": Timestamp.now(),
    });

    commentController.clear();
    Navigator.pop(context);
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
              imageUrl: widget.imageUrl,
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
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16.0),
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                                // Add more text or widgets as needed
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Column(
                                children: [
                                  LikedButton(
                                    isLiked: isLiked,
                                    onTap: toggleLike,
                                  ),
                                  Text(widget.likes.length.toString()),
                                ],
                              ),
                              SizedBox(height: 10),
                              IconButton(
                                icon: Icon(Icons.comment),
                                onPressed: () => showCommentDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("Posts")
                          .doc(widget.pId)
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
                            DateTime commentTime =
                            (comment["CommentTime"] as Timestamp).toDate();
                            String formattedDate =
                            DateFormat('dd/MM/yyyy').format(commentTime);
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
