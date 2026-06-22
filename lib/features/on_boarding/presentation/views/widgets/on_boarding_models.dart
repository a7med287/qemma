import 'package:flutter/material.dart';

/// One of the 6 "ليه تختار قِمّة؟" feature cards.
class OnBoardingFeatureModel {
  const OnBoardingFeatureModel({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}

/// One of the 4 "كيف قِمّة بتسهل عليك؟" step cards.
class OnBoardingStepModel {
  const OnBoardingStepModel({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}
