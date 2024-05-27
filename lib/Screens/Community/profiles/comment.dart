import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class Comment extends StatefulWidget {
  final String text;
  final String user;
  final String time;

  const Comment({
    super.key,
    required this.text,
    required this.user,
    required this.time
  });

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final postRef = FirebaseDatabase.instance.reference().child('Posts');
  // firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
