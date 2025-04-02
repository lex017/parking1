import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:parking1/menu/emp_main.dart';
import 'package:parking1/model/userdata.dart';
import 'package:shared_preferences/shared_preferences.dart';

class emp_login extends StatefulWidget {
  const emp_login({super.key});

  @override
  State<emp_login> createState() => _emp_loginState();
}

class _emp_loginState extends State<emp_login> {
  bool obs = true;
  final formkey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool isLoading = false;


  final TextEditingController emailController =
      TextEditingController(); // emp_id
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCredentials();
  }

  Future<void> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('emp_id') ?? '';
      passwordController.text = prefs.getString('pass_emp') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });

    if (rememberMe) {
      await loginWithFirestore();
    }
  }

  Future<void> loginWithFirestore() async {
  try {
    final empId = emailController.text.trim();
    final password = passwordController.text.trim();

    final doc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(empId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['pass_emp'] == password) {
        // Successful login
        await saveCredentials();
        Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => emp_main(empId: empId)),
        (route) => route.isFirst, // Keep only the first route (HomePage)
      );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employee found with this emp_id.')),
      );
    }
  } catch (e) {
   
  }
}


  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('emp_id', emailController.text);
      await prefs.setString('pass_emp', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('emp_id');
      await prefs.remove('pass_emp');
      await prefs.remove('rememberMe');
    }
  }

  void showMessage() {
    setState(() {
      obs = !obs;
    });
  }

 

  Widget emailInput() {
    return SizedBox(
      width: 350,
      child: TextFormField(
        controller: emailController,
        validator: RequiredValidator(errorText: "Please enter an emp_id"),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Emp_id',
          labelStyle: TextStyle(color: Colors.black),
          prefixIcon: Icon(
            Icons.person,
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
        controller: passwordController,
        obscureText: obs,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          return null;
        },
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          labelText: 'Password',
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: const Icon(
            Icons.key,
            color: Colors.black,
            size: 35.0,
          ),
          suffixIcon: IconButton(
            onPressed: showMessage,
            icon: const Icon(Icons.visibility),
          ),
        ),
      ),
    );
  }

  Widget rememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          onChanged: (value) {
            setState(() {
              rememberMe = value ?? false;
            });
          },
        ),
        const Text(
          "Remember Me",
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget loginButton() {
  return SizedBox(
    width: 350,
    height: 50,
    child: ElevatedButton(
      onPressed: () async {
        if (formkey.currentState?.validate() ?? false) {
          setState(() {
            isLoading = true;
          });

          await loginWithFirestore();

          setState(() {
            isLoading = false;
          });
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            )
          : const Text(
              "Login",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LOGIN_Employee'),),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 100.0),
                          emailInput(),
                          const SizedBox(height: 50.0),
                          passwordInput(),
                          const SizedBox(height: 30.0),
                          rememberMeCheckbox(),
                          const SizedBox(height: 50.0),
                          loginButton(),
                          const SizedBox(height: 20.0),
                        ],
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
}
