import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';
import 'scan_screen.dart';
import 'login.dart';

class MenuScreen extends StatelessWidget {
  
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    const bgColor = Color(0xFFF1EFEA);
    const navColor = Color(0xFFB8F57C);
    const iconColor = Color(0xFF0A2418);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Text(
            user != null ? 'Welcome, ${user.email}' : 'Not logged in',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: h * 0.08,
        width: h * 0.08,
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: navColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanScreen(),
              ),
            );
          },
          child: Icon(
            Icons.print,
            size: w * 0.07,
            color: iconColor,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(w * 0.01, 0, w * 0.01, h * 0.01),
        child: Container(
          height: h * 0.07,
          decoration: BoxDecoration(
            color: navColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: EdgeInsets.only(left: w * 0.03),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.home,
                    size: w * 0.09,
                    color: iconColor,
                  ),
                ),
              ),
              SizedBox(width: w * 0.13),
              Padding(
                padding: EdgeInsets.only(right: w * 0.03),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.person,
                    size: w * 0.09,
                    color: iconColor,
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