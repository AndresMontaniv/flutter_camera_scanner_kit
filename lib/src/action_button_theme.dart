import 'package:flutter/material.dart';

enum ActionButtonTheme {
  light,
  dark;

  ButtonStyle get buttonStyle {
    switch (this) {
      case ActionButtonTheme.light:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xD9FFFFFF)),
          iconColor: WidgetStatePropertyAll(Colors.black87),
        );
      case ActionButtonTheme.dark:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.black54),
          iconColor: WidgetStatePropertyAll(Colors.white),
        );
    }
  }
}
