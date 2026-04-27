  import 'package:flutter/material.dart';
  import 'splash_screen.dart';
  class SoilTechApp extends StatelessWidget {
    const SoilTechApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'SoilTech',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        ),
      home: const SplashScreen(), // change this from LoginScreen
      );
    }
  }/*  */
  