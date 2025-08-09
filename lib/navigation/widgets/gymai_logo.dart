import 'package:flutter/material.dart';
import '../constants/navigation_constants.dart';

class GymaiLogo extends StatelessWidget {
  final double size;
  final bool isAnimated;

  const GymaiLogo({
    Key? key,
    this.size = NavigationConstants.defaultLogoSize,
    this.isAnimated = NavigationConstants.defaultLogoAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // دمبل بزرگ مشکی در وسط
          Icon(
            Icons.fitness_center,
            color: Colors.black,
            size: size * 1,
          ),

          SizedBox(height: size * 0.03),

          // متن gym ai
          Text(
            'GYM AI',
            style: TextStyle(
              color: Colors.black,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
