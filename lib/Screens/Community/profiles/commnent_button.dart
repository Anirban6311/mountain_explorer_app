import 'package:flutter/material.dart';

class CommentButton extends StatelessWidget {
  final void Function()? onTap;

  CommentButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.comment_outlined),
    );
  }
}
