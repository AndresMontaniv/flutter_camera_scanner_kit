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
  Color get backgroundColor => this == ActionButtonTheme.dark ? _darkBgColor : _white85;
  Color get foregroundColor => this == ActionButtonTheme.dark ? _darkForegroundColor : _lightForegroundColor;
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

    final bool isDisabled = onPressed == null;
    final double opacityFactor = isDisabled ? 0.4 : 1.0;

    return Material(
      color: actionButtonTheme.backgroundColor.withValues(
        alpha: actionButtonTheme.backgroundColor.a * opacityFactor,
      ),
      clipBehavior: Clip.antiAlias,
      shape: CircleBorder(
        side: BorderSide(
          color: actionButtonTheme.borderColor.withValues(
            alpha: actionButtonTheme.borderColor.a * opacityFactor,
          ),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: size,
            color: actionButtonTheme.foregroundColor.withValues(
              alpha: actionButtonTheme.foregroundColor.a * opacityFactor,
            ),
          ),
        ),
      ),
    );
  }
}
