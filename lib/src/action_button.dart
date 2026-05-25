import 'package:flutter/material.dart';

const _lightForegroundColor = Colors.black87;
const _darkBgColor = Colors.black54;
const _darkForegroundColor = Colors.white;
const _white85 = Color(0xD9FFFFFF);
const _grey60 = Color(0x999E9E9E);

enum ActionButtonTheme {
  light,
  dark
  ;

  Color get borderColor => this == ActionButtonTheme.dark ? _white85 : _grey60;

  ButtonStyle get buttonStyle {
    switch (this) {
      case ActionButtonTheme.light:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(_white85),
          iconColor: WidgetStatePropertyAll(_lightForegroundColor),
          foregroundColor: WidgetStatePropertyAll(_lightForegroundColor),
          shape: WidgetStatePropertyAll(CircleBorder(side: BorderSide(color: _grey60))),
        );
      case ActionButtonTheme.dark:
        return const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(_darkBgColor),
          iconColor: WidgetStatePropertyAll(_darkForegroundColor),
          foregroundColor: WidgetStatePropertyAll(_darkForegroundColor),
          shape: WidgetStatePropertyAll(CircleBorder(side: BorderSide(color: _white85))),
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
