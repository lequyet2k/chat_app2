import 'package:flutter/material.dart';
import 'package:my_porject/screens/auth_screen.dart';
import 'package:my_porject/screens/login_signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 2,),
            Image.asset("assets/images/welcome_image.png"),
            Spacer(flex: 3,),
            Text(
              "Welcome to our freedom \n messaging app",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                .textTheme
                .headline5
                ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              "Free chat",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.color
                    ?.withOpacity(0.64),
              ),
            ),
            Spacer(flex: 3,),
            FittedBox(
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SigninOrSignupScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        "Next",
                        style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Theme.of(context).textTheme.bodyText1?.color?.withOpacity(0.8)),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withOpacity(0.8),
                      )
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }
}