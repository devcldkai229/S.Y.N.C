import 'package:flutter/material.dart';

Widget buildLocalFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return const ColoredBox(
    color: Color(0xFFE8EDEB),
    child: Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
    ),
  );
}
