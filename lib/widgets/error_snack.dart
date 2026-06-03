import 'package:flutter/material.dart';

/// Shows a consistent error SnackBar from any caught exception.
void showErrorSnack(BuildContext context, Object error, {String? prefix}) {
  final message = prefix == null ? '$error' : '$prefix: $error';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ),
  );
}

