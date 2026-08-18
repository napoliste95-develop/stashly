import 'package:flutter/material.dart';

const List<Color> categoryColorPalette = [
  Color(0xFFEF5350),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF7E57C2),
  Color(0xFF5C6BC0),
  Color(0xFF42A5F5),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFF9CCC65),
  Color(0xFFFFCA28),
  Color(0xFFFFA726),
  Color(0xFF8D6E63),
];

class Category {
  final String id;
  final String name;
  final Color color;

  Category({required this.id, required this.name, required this.color});

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] as String? ?? '',
      color: Color(data['color'] as int? ?? categoryColorPalette.first.toARGB32()),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'color': color.toARGB32(),
      };

  factory Category.fromJson(String id, Map<String, dynamic> json) {
    return Category(
      id: id,
      name: json['name'] as String? ?? '',
      color: Color(json['color'] as int? ?? categoryColorPalette.first.toARGB32()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.toARGB32(),
      };
}
