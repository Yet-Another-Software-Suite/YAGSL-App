import 'package:flutter/material.dart';

class ConfigMenuButton extends StatelessWidget {
  final String label;
  final bool isComplete;
  final VoidCallback onPressed;

  const ConfigMenuButton({
    Key? key,
    required this.label,
    required this.isComplete,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(
        isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isComplete ? Colors.green : Colors.grey,
        size: 24.0,
      ),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size(double.infinity, 50),
        shape: const BeveledRectangleBorder(),
      ),
    );
  }
}
