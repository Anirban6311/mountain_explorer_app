import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'communityHome.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool showSpinner = false;

  String email = "", password = "", name = "";

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Images/login_bg.png'), // Replace with your background image asset path
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "Create account",
                        style: GoogleFonts.montserrat(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 40),
                        child: Text(
                          "Share your experience with the trek community!",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Form(
                        key: _formKey, // Add the form key here
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: "Username",
                                labelText: "Username",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (String value) {
                                name = value;
                              },
                              validator: (value) {
                                return value!.isEmpty ? "Enter Username" : null;
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "Email",
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (String value) {
                                  email = value;
                                },
                                validator: (value) {
                                  return value!.isEmpty ? "Enter Email" : null;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: TextFormField(
                                controller: passwordController,
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (String value) {
                                  password = value;
                                },
                                validator: (value) {
                                  return value!.isEmpty ? "Enter Password" : null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFfeda75), // Instagram gradient colors
                                    Color(0xFFfa7e1e),
                                    Color(0xFFd62976),
                                    Color(0xFF962fbf),
                                    Color(0xFF4f5bd5),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      showSpinner = true;
                                    });
                                    try {
                                      final userCredential = await _auth.createUserWithEmailAndPassword(
                                        email: email.trim(),
                                        password: password.trim(),
                                      );

                                      User? user = userCredential.user;

                                      if (user != null) {
                                        await user.updateDisplayName(name);
                                        await user.reload();
                                        user = _auth.currentUser;

                                        print("Success");
                                        ToastMessages("User successfully created");
                                        setState(() {
                                          showSpinner = false;
                                        });
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => communityHome()));
                                      }
                                    } catch (e) {
                                      print(e.toString());
                                      ToastMessages(e.toString());
                                      setState(() {
                                        showSpinner = false;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // To maintain the gradient color
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Container(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already a user? ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Login',
                                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
