import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:my_porject/screens/chathome_screen.dart';
import 'package:my_porject/provider/user_provider.dart';
import 'package:my_porject/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:my_porject/screens/auth_screen.dart';
import 'package:my_porject/components/upside.dart';
import 'package:provider/provider.dart';


// ignore: must_be_immutable
class Login extends StatefulWidget {
  String? email;
  String? password;
  Login({this.email,this.password});
  @override
  State<Login> createState() => LoginPage();
}

class LoginPage extends State<Login> {
  final TextEditingController? _email = TextEditingController();
  final TextEditingController? _password =  TextEditingController();
  late final String imgUrl;
  bool isLoading = false;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _email?.text = widget.email ?? "";
    _password?.text = widget.password ?? "" ;
  }
  void updateStatus(){
    setState(() {
      _isVisible = !_isVisible;
    });
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  showLoginDialog(bool bol) {
    if(bol == false) {
      return AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Log In Failed',
          desc: 'The email address is badly formatted',
          btnCancelText: 'Log In Again',
          btnCancelIcon: Icons.arrow_back_ios,
          btnCancelOnPress: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Login())
            );
          }
      )..show();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: isLoading
          ? Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 20 ,
          width: MediaQuery.of(context).size.height / 20 ,
          child: const CircularProgressIndicator(),
        ),
      ) : Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              const Upside(imgUrl : "assets/images/logo.png",),
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
                      )
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 15),
                        child: const Text(
                          "Login to your account",
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
                child: Container(
                  width: double.infinity,
                  height: 600,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                        topLeft: Radius.circular(50),
                      )
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20,),
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
                            //     onPressed: () async {},
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
                                    if(user != null) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomeScreen(user: user,),
                                          ));
                                      print("Login Successfull");
                                    } else {
                                      showLoginDialog(false);
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
                      const SizedBox(height: 5,),
                      const Text(
                        'or use your email account',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'OpenSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              width: 320,
                              margin: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.email),
                                    hintText: "Email",
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20)
                                    )
                                ),
                                controller: _email,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && value.length < 10 ) {
                                    return "Phải lớn hơn 10 ký tự!";
                                  } else if(value == null || value.isEmpty) {
                                    return "Không được để trống!";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Container(
                              width: 320,
                              margin: const EdgeInsets.all(5.0),
                              child: TextFormField(
                                obscureText: _isVisible ? false : true,
                                decoration: InputDecoration(
                                    prefixIcon: const Padding(
                                      padding: EdgeInsetsDirectional.only(start: 12),
                                      child: Icon(Icons.password),
                                    ),
                                    hintText: "Password",
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsetsDirectional.only(end: 12),
                                      child: IconButton(
                                        onPressed: () => updateStatus(),
                                        icon: Icon(_isVisible ? Icons.visibility : Icons.visibility_off),
                                      ),
                                    )),
                                controller: _password,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Không được để trống!";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10,),
                      SizedBox(
                        width: 200,
                        height: 35,
                        child: ElevatedButton(
                          onPressed: () {
                            if(_formKey.currentState!.validate()){
                              if((_email!.text.isNotEmpty && _password!.text.isNotEmpty)){
                                setState(() {
                                  isLoading = true;
                                });
                                logIn(_email!.text, _password!.text).then((user) {
                                  if(user != null) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => HomeScreen(user: user,)),
                                    );
                                    print("Login Successful");
                                  } else {
                                    showLoginDialog(false);
                                    print("Login Failed");
                                  }
                                });
                              } else {

                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child:
                          const Text("LOGIN", style: TextStyle(color: Colors.white,fontSize: 15,)),
                        ),
                      ),
                      const SizedBox(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'OpenSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5,),
                          TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignUp(),
                                    ));
                              },
                              child: const Text(
                                "Register here",
                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


