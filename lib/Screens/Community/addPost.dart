import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  bool showSpinner = false;
  final postRef = FirebaseDatabase.instance.reference().child('Posts');
  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  FirebaseAuth _auth=FirebaseAuth.instance;

  File? _image;
  final picker = ImagePicker();

  Future getImageGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (picked != null) {
        _image = File(picked.path);
      } else {
        print("Image not picked");
      }
    });
  }

  Future getImageCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (picked != null) {
        _image = File(picked.path);
      } else {
        print("Image not picked");
      }
    });
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Container(
            height: 120,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    getImageCamera();
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.camera),
                    title: Text("Camera"),
                  ),
                ),
                InkWell(
                  onTap: () {
                    getImageGallery();
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.browse_gallery),
                    title: Text("Gallery"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 60),
              Center(
                child: InkWell(
                  onTap: () {
                    dialog(context);
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * .2,
                    width: MediaQuery.of(context).size.width,
                    child: _image != null
                        ? ClipRect(
                      child: Image.file(
                        _image!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: 100,
                      height: 100,
                      child: Icon(
                        Icons.camera,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Title",
                        hintText: "Enter post title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: descriptionController,
                      keyboardType: TextInputType.text,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Description",
                        hintText: "Enter post description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async{
                  setState(() {
                    showSpinner=true;
                  });
                  try{

                    int date=DateTime.now().microsecondsSinceEpoch;

                    //Image uploading
                    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref('/monuments_app$date');
                    UploadTask uploadTask = ref.putFile(_image!.absolute);
                    await Future.value(uploadTask);
                    var newUrl=await ref.getDownloadURL();

                    final User? user = _auth.currentUser;

                    //Image storing in database
                    postRef.child('Post List').child(date.toString()).set(
                        {
                          'pId': date.toString(),
                          'pImage': newUrl.toString(),
                          'pTime': date.toString(),
                          'pTitle': titleController.text.toString(),
                          'pDescription': descriptionController.text.toString(),
                          'uEmail': user!.email.toString(),
                          'uid': user!.uid.toString(),
                        }).then((value) {
                       ToastMessages("Post Uploaded");
                       setState(() {
                         showSpinner=false;
                       });

                    }).onError((error, stackTrace){
                      ToastMessages(error.toString());
                      setState(() {
                        showSpinner=false;
                      });
                    });

                  }catch(e){
                    setState(() {
                      showSpinner=false;
                    });
                    ToastMessages(e.toString());
                  }

                },
                child: Text("Post your story"),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void ToastMessages(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
