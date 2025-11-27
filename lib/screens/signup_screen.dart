import 'package:flutter/material.dart';
import 'package:my_porject/screens/auth_screen.dart';
import 'package:my_porject/screens/login_screen.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/components/upside_signup.dart';

class SignUp extends StatefulWidget {
  const SignUp({key});

  @override
  State createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUp> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController passwordAgain = TextEditingController();
  bool isLoading = false;

  bool _isVisible = false;
  void updateStatus() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void showRegisterSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        content: Text(
          'Account created successfully! Please login to continue.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Login(
                    email: email.text,
                    password: password.text,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Login Now', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void showRegisterFailedDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Text(
              'Registration Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isLoading = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  String? validatePassword(String value) {
    RegExp regex = RegExp(r'^(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    if (!regex.hasMatch(value)) {
      return 'Phải có tối thiểu 1 chữ cái, 1 số và 1 ký tự đặc biệt';
    } else {
      return null;
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return isLoading
        ? Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height / 20,
              width: MediaQuery.of(context).size.height / 20,
              child: const CircularProgressIndicator(),
            ),
          )
        : GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: SingleChildScrollView(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      const Upside(
                        imgUrl: "assets/images/logo.png",
                      ),
                      Positioned(
                        top: 230,
                        left: 0,
                        right: 0,
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: const BoxDecoration(
                              color: Color(0xfffeeeee4),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(50),
                                topLeft: Radius.circular(50),
                              )),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 15),
                                child: const Text(
                                  "Create New Account",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 17,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xfff575861),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 280,
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: size.height - 280,
                            ),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(50),
                                  topLeft: Radius.circular(50),
                                )),
                            child: Column(
                          children: [
                            const SizedBox(
                              height: 7,
                            ),
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  // SizedBox(
                                  //   height: 40,
                                  //   width: 40,
                                  //   child: IconButton(
                                  //     icon: Image.asset(
                                  //       "assets/images/facebook_icon.png",
                                  //     ),
                                  //     onPressed: () async {
                                  //       // signInWithFacebook();
                                  //       setState(() {
                                  //         isLoading = true;
                                  //       });
                                  //       signInWithFacebook().then((user) {
                                  //         if(user != null) {
                                  //           setState(() {
                                  //             isLoading = false;
                                  //           });
                                  //           Navigator.push(
                                  //               context,
                                  //               MaterialPageRoute(
                                  //                 builder: (context) => HomeScreen(user: user,),
                                  //               ));
                                  //           print("Login Successfull");
                                  //         } else {
                                  //           print("Login Failed");
                                  //         }
                                  //       });
                                  //     },
                                  //   ),
                                  // ),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: IconButton(
                                      iconSize: 20,
                                      icon: Image.asset(
                                        "assets/images/google_icon.png",
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        signInWithGoogle().then((user) {
                                          if (user != null) {
                                            setState(() {
                                              isLoading = false;
                                            });
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            HomeScreen(
                                                                user: user)),
                                                    (Route<dynamic> route) =>
                                                        false);
                                            print("Login Successfully");
                                          } else {
                                            setState(() {
                                              isLoading = false;
                                            });
                                            showRegisterFailedDialog('Google sign in failed or was cancelled.');
                                            print("Login Failed");
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // SizedBox(
                                  //   height: 40,
                                  //   width: 40,
                                  //   child: IconButton(
                                  //     iconSize: 1,
                                  //     icon: Image.asset(
                                  //       "assets/images/apple_icon.png",
                                  //     ),
                                  //     onPressed: () {},
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            const Text(
                              'or use your email account',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'OpenSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 320,
                                      margin: const EdgeInsets.only(bottom: 5),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                            prefixIcon: const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 12),
                                              child: Icon(Icons.account_circle),
                                            ),
                                            hintText: "Name",
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20))),
                                        controller: name,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Không được để trống!";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 320,
                                      margin: const EdgeInsets.all(5.0),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                            prefixIcon: const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 12),
                                              child: Icon(Icons.email),
                                            ),
                                            hintText: "Email",
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20))),
                                        controller: email,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Không được để trống!";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 320,
                                      margin: const EdgeInsets.all(5.0),
                                      child: TextFormField(
                                        obscureText: _isVisible ? false : true,
                                        decoration: InputDecoration(
                                            prefixIcon: const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 12),
                                              child: Icon(Icons.password),
                                            ),
                                            hintText: "Password",
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            suffixIcon: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 12),
                                              child: IconButton(
                                                onPressed: () => updateStatus(),
                                                icon: Icon(_isVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off),
                                              ),
                                            )),
                                        controller: password,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Không được để trống!";
                                          } else if (value.length < 6) {
                                            return "Mật khẩu phải dài hơn 6 ký tự";
                                          } else {
                                            return validatePassword(value);
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 320,
                                      margin: const EdgeInsets.all(5.0),
                                      child: TextFormField(
                                        obscureText: _isVisible ? false : true,
                                        decoration: InputDecoration(
                                            prefixIcon: const Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 12),
                                              child: Icon(Icons.password),
                                            ),
                                            hintText: "Confirm Password",
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            suffixIcon: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 12),
                                              child: IconButton(
                                                onPressed: () => updateStatus(),
                                                icon: Icon(_isVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off),
                                              ),
                                            )),
                                        controller: passwordAgain,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Không được để trống!";
                                          } else if (value != password.text) {
                                            return "Không trùng với mật khẩu vừa nhập";
                                          } else {
                                            return null;
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                )),
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              width: 200,
                              height: 35,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (name.text.isNotEmpty &&
                                        email.text.isNotEmpty &&
                                        password.text.isNotEmpty) {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      createAccount(name.text, email.text,
                                              password.text)
                                          .then((result) {
                                        if (result.isSuccess && result.user != null) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          showRegisterSuccessDialog();
                                          print("Registration Successful");
                                        } else {
                                          showRegisterFailedDialog(result.errorMessage ?? 'Registration failed. Please try again.');
                                          print("Registration Failed: ${result.errorMessage}");
                                        }
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: const Text("REGISTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    )),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'OpenSans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Login(
                                              email: email.text,
                                              password: password.text,
                                            ),
                                          ));
                                    },
                                    child: const Text(
                                      "Login here",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ))
                              ],
                            ),
                          ],
                        ),
                      ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
