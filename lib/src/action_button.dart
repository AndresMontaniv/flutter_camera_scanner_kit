import 'package:flutter/material.dart';

enum ActionButtonTheme {
  light,
  dark
  ;

  ButtonStyle get buttonStyle {
    switch (this) {
      case ActionButtonTheme.light:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xD9FFFFFF)),
          iconColor: WidgetStatePropertyAll(Colors.black87),
          shape: WidgetStatePropertyAll(CircleBorder(side: BorderSide(color: Color(0x999E9E9E)))),
        );
      case ActionButtonTheme.dark:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.black54),
          iconColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(CircleBorder(side: BorderSide(color: Color(0xD9FFFFFF)))),
        );
    }
  }
}

class CircleButton extends StatelessWidget {
  final IconData icon;
  final bool darkMode;
  final double size;
  final VoidCallback? onPressed;

  const CircleButton({
    super.key,
    required this.icon,
    required this.size,
    required this.darkMode,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final actionButtonTheme = darkMode ? ActionButtonTheme.dark : ActionButtonTheme.light;
    return IconButton(
      icon: Icon(icon, size: size),
      style: actionButtonTheme.buttonStyle,
      onPressed: onPressed,
    );
  }
}
