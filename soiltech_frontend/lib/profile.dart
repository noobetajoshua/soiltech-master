import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF1EFEA);
    const greenColor = Color(0xFFA8EA7A);
    const darkGreen = Color(0xFF163C1F);
    const borderColor = Color(0xFF7D9C74);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: greenColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.elliptical(220, 90),
                        bottomRight: Radius.elliptical(220, 90),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 130,
                    child: Container(
                      width: 124,
                      height: 106,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_circle,
                          size: 70,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'USERNAME',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
