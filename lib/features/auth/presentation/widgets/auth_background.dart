import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final bool isSignIn;

  const AuthBackground({super.key, this.isSignIn = true});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final saffronColor = const Color(0xFFDB7E20);
    final darkerSaffron = const Color.fromARGB(255, 180, 95, 10);
    final lightGrey = const Color(0xFFF0F0F0);

    return Stack(
      children: [
        // Base background color
        Container(color: const Color(0xFFF9F9F9)),

        // Faint grey blob on the mid-left
        Positioned(
          top: size.height * 0.3,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: lightGrey,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Darker Pink blob top right
        Positioned(
          top: -120,
          right: 20,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: darkerSaffron,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Main Pink blob top right
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: saffronColor,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Bottom Pink Area
        Positioned(
          bottom: isSignIn ? -size.width * 0.5 : -size.width * 0.8,
          left: -size.width * 0.2,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 1.4,
            height: size.width * 1.4,
            decoration: BoxDecoration(
              color: saffronColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Bottom darker pink overlay (for depth matching image)
        Positioned(
          bottom: isSignIn ? -size.width * 0.6 : -size.width * 0.9,
          right: -size.width * 0.2,
          child: Container(
            width: size.width * 1.2,
            height: size.width * 1.2,
            decoration: BoxDecoration(
              color: darkerSaffron.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
