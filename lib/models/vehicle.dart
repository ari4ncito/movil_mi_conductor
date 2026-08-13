import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final String brand;
  final String plates;
  final String color;
  final String year;
  final IconData icon;
  final Color iconColor;

  Vehicle({
    required this.id,
    required this.brand,
    required this.plates,
    required this.color,
    required this.year,
    required this.icon,
    required this.iconColor,
  });

  Vehicle copyWith({
    String? id,
    String? brand,
    String? plates,
    String? color,
    String? year,
    IconData? icon,
    Color? iconColor,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      plates: plates ?? this.plates,
      color: color ?? this.color,
      year: year ?? this.year,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}
