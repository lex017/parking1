import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:parking1/menu/emp_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class emp_login extends StatefulWidget {
  const emp_login({super.key});

  @override
  State<emp_login> createState() => _EmpLoginState();
}

class _EmpLoginState extends State<emp_login> {
  final formkey = GlobalKey<FormState>();
  final TextEditingController emailController =
      TextEditingController(); // emp_id
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCredentials();
  }

  Future<void> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('emp_id') ?? '';
      passwordController.text = prefs.getString('emp_password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });

    if (rememberMe && emailController.text.isNotEmpty) {
      await loginWithFirestore();
    }
  }

  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('emp_id', emailController.text);
      await prefs.setString('emp_password', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('emp_id');
      await prefs.remove('emp_password');
      await prefs.remove('rememberMe');
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
        if (data != null &&
            data['emp_id'] == empId &&
            data['password'] == password) {
          await saveCredentials();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => emp_main(empId: empId)),
            (route) => route.isFirst,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid employee ID or password.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee not found.')),
        );
      }
    } catch (e) {
      print("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
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
        obscureText: true,
        validator: RequiredValidator(errorText: "Please enter password"),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Password',
          labelStyle: TextStyle(color: Colors.black),
          prefixIcon: Icon(
            Icons.lock,
            color: Colors.black,
            size: 35.0,
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
      appBar: AppBar(title: const Text('LOGIN_Employee')),
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
                          const SizedBox(height: 20.0),
                          passwordInput(),
                          const SizedBox(height: 50.0),
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
