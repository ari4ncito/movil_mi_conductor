import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final String brand;
  final String model;
  final String plates;
  final String color;
  final String year;
  final IconData icon;
  final Color iconColor;

  Vehicle({
    required this.id,
    required this.brand,
    this.model = '',
    required this.plates,
    required this.color,
    required this.year,
    required this.icon,
    required this.iconColor,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      brand: (json['marca'] ?? json['brand'] ?? '').toString(),
      model: (json['modelo'] ?? json['model'] ?? '').toString(),
      plates: (json['placa'] ?? json['plates'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      year: (json['anio'] ?? json['year'] ?? '').toString(),
      icon: Icons.directions_car_outlined,
      iconColor: const Color(0xFF334A52),
    );
  }

  Vehicle copyWith({
    String? id,
    String? brand,
    String? model,
    String? plates,
    String? color,
    String? year,
    IconData? icon,
    Color? iconColor,
  }) {
    return Vehicle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plates: plates ?? this.plates,
      color: color ?? this.color,
      year: year ?? this.year,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}
