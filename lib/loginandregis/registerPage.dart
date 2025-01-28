import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:parking1/loginandregis/loginPage.dart';
import 'package:parking1/model/userdata.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool obs = true;

  void showMessage() {
    setState(() {
      obs = !obs;
    });
  }

  final formkey = GlobalKey<FormState>();
  Userparking myUser = Userparking();

  Widget showText() {
    return Text(
      "Sign up",
      style: TextStyle(
        fontSize: 35.0,
        fontWeight: FontWeight.bold,
        color: Colors.blue[900],
        fontFamily: 'Lobster',
      ),
    );
  }

  Widget showText1() {
    return Text(
      "Create a new account",
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Lobster',
      ),
    );
  }

  Widget userInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (String? username) {
          myUser.username = username ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a username';
          }
          return null;
        },
        decoration: InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Username',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.person,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  Widget emailInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        onSaved: (String? email) {
          myUser.email = email ?? '';
        },
        validator: MultiValidator([
          RequiredValidator(errorText: "Please enter an email"),
          EmailValidator(errorText: "Please enter a valid email")
        ]),
        decoration: InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Email',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.email,
            color: Colors.black,
            size: 35.0,
          ),
        ),
      ),
    );
  }

  Widget passwordInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        obscureText: obs,
        onSaved: (String? pass) {
          myUser.Pass = pass ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          return null;
        },
        decoration: InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Password',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.key,
            color: Colors.black,
            size: 35.0,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              showMessage();
            },
            icon: const Icon(Icons.visibility),
          ),
        ),
      ),
    );
  }

  Widget passConfirm() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        obscureText: obs,
        onSaved: (String? passConfirm) {
          myUser.passconfilm = passConfirm ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          return null;
        },
        decoration: InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Confirm Password',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.key,
            color: Colors.black,
            size: 35.0,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              showMessage();
            },
            icon: const Icon(Icons.visibility),
          ),
        ),
      ),
    );
  }

  Widget signupButton() {
    return SizedBox(
      width: 350,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          if (formkey.currentState?.validate() ?? false) {
            formkey.currentState?.save();

            if (myUser.Pass != myUser.passconfilm) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Passwords do not match!')),
              );
              return;
            }

            try {
              final userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: myUser.email,
                password: myUser.Pass,
              );

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCredential.user?.uid)
                  .set({
                'username': myUser.username,
                'email': myUser.email,
              });

              formkey.currentState?.reset();
              myUser = Userparking();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User created successfully!')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const loginPage()),
              );
            } on FirebaseAuthException catch (e) {
              String errorMessage = 'Something went wrong!';

              if (e.code == 'email-already-in-use') {
                errorMessage = 'This email is already in use.';
              } else if (e.code == 'weak-password') {
                errorMessage = 'The password is too weak.';
              } else if (e.code == 'invalid-email') {
                errorMessage = 'The email address is invalid.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('An unexpected error occurred.')),
              );
            }
          }
        },
        child: Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget login() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const loginPage()),
            );
          },
          child: Text(
            "Click here",
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: const BoxDecoration(color: Colors.white),
          child: Form(
            key: formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30.0),
                      showText(),
                      const SizedBox(height: 10.0),
                      showText1(),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40.0),
                      userInput(),
                      const SizedBox(height: 40.0),
                      emailInput(),
                      const SizedBox(height: 40.0),
                      passwordInput(),
                      const SizedBox(height: 40.0),
                      passConfirm(),
                      const SizedBox(height: 50.0),
                      signupButton(),
                      login(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

}
