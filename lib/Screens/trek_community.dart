import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                Text(post.date),
                SizedBox(height: 16.0),
                Text(post.content),
                SizedBox(height: 8.0),
                if (post.image != null)
                  Image.network(
                    post.image!,
                    height: 200.0,
                    fit: BoxFit.cover,
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
}

class TrekkerBlogPost {
  final String title;
  final String author;
  final String date;
  final String content;
  final String? image;

  TrekkerBlogPost({
    required this.title,
    required this.author,
    required this.date,
    required this.content,
    this.image,
  });

  factory TrekkerBlogPost.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TrekkerBlogPost(
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      date: data['date'] ?? '',
      content: data['content'] ?? '',
      image: data['image'],
    );
  }
}

class CreateBlogScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  void _createPost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('community_posts').doc('posts').collection('posts').add({
        'title': titleController.text,
        'author': authorController.text,
        'date': DateTime.now().toString(),
        'content': contentController.text,
        // Add image URL if needed
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
