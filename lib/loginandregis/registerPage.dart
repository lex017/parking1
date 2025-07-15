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
      color: Colors.blue, // Dynamically adjust color
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
      color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamically adjust color
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30)
          ),
        labelText: 'Username',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface, // Background color based on theme
        prefixIcon: Icon(
          Icons.person,
          color: Theme.of(context).iconTheme.color, // Dynamically adjust icon color
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30)
          ),
        labelText: 'Email',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface, // Background color based on theme
        prefixIcon: Icon(
          Icons.email,
          color: Theme.of(context).iconTheme.color, // Dynamically adjust icon color
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30)
          ),
        labelText: 'Password',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface, // Background color based on theme
        prefixIcon: Icon(
          Icons.key,
          color: Theme.of(context).iconTheme.color, // Dynamically adjust icon color
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30)
          ),
        labelText: 'Confirm Password',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface, // Background color based on theme
        prefixIcon: Icon(
          Icons.key,
          color: Theme.of(context).iconTheme.color, // Dynamically adjust icon color
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

Widget signupButton(BuildContext context, GlobalKey<FormState> formkey, Userparking myUser) {
  bool isLoading = false;

  return SizedBox(
    width: 350,
    height: 50,
    child: ElevatedButton(
      onPressed: () async {
        if (isLoading) return; // Prevent multiple submissions

        setState(() {
          isLoading = true; // Start loading
        });

        if (formkey.currentState?.validate() ?? false) {
          formkey.currentState?.save();

          if (myUser.Pass != myUser.passconfilm) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Passwords do not match!')),
            );
            setState(() {
              isLoading = false; // Reset loading state
            });
            return;
          }

          try {
            final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: myUser.email,
              password: myUser.Pass,
            );

            await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
              'username': myUser.username,
              'email': myUser.email,
              'password': myUser.passconfilm,
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
          } finally {
            setState(() {
              isLoading = false; // Reset loading state when done
            });
          }
        }
      },
      child: isLoading
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              "Sign Up",
              style: TextStyle(
                color: Colors.white, // Adjust icon color dynamically
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent, // Adjust button color based on theme
      ),
    ),
  );
}

Widget login() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Text(
          "Already have an account?",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).iconTheme.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const loginPage()),
          );
        },
        child: const Text(
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
  backgroundColor: Theme.of(context)
                  .scaffoldBackgroundColor, // Dynamic background color based on the theme
  body: SingleChildScrollView(
    child: Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background, // Use dynamic background color based on theme
        ),
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
                    const SizedBox(height: 40.0),  // Combined the top space
                    userInput(),
                    const SizedBox(height: 40.0),
                    emailInput(),
                    const SizedBox(height: 40.0),
                    passwordInput(),
                    const SizedBox(height: 40.0),
                    passConfirm(),
                    const SizedBox(height: 50.0),
                    signupButton(context, formkey, myUser),
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