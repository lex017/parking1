import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:parking1/loginandregis/loginPage.dart';


class firstpage extends StatefulWidget {
  const firstpage({super.key});

  @override
  State<firstpage> createState() => _firstpageState();
}

class _firstpageState extends State<firstpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 30, 203, 255),
        body: Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 50,
                ),
                FadeInRight(
                  duration: Duration(milliseconds: 1500),
                  child: Image.network(
                    'https://media.giphy.com/media/EiQE8JWMw3DvJEOhjH/giphy.gif?cid=ecf05e474lfxj705ezbb9y4btpcnd2nt0elf4sjrqyn5jhu1&ep=v1_gifs_related&rid=giphy.gif&ct=g',
                    fit: BoxFit.cover,
                  ),
                ),
                FadeInUp(
                  duration: Duration(milliseconds: 1000),
                  delay: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.only(bottom: 50,left: 40,top: 40,right: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          delay: Duration(milliseconds: 1000),
                          child: Text(
                            "Welcome",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          delay: Duration(milliseconds: 1000),
                          child: Text(
                            "this app Simplify Your Parking Journey – Find, Reserve, Park! \nThis app is the simplest way to pay your parking using your smartphone only",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                        SizedBox(height: 20,),
                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          delay: Duration(milliseconds: 1000),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                                onPressed: () {
                                   Navigator.push(
                                            context,
                                  MaterialPageRoute(builder: (ctx) => const loginPage()),
                                                  );
                                },
                                child: Text(
                                  "CLICK NOW ->",
                                  style: TextStyle(color: Colors.black, fontSize: 18),
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )));
  }
}
