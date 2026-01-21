import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ValidationStatus { unknown, valid, invalid }

class ValidationState {
  final ValidationStatus status;
  final String message;

  const ValidationState._(this.status, this.message);

  const ValidationState.unknown() : this._(ValidationStatus.unknown, '');
  const ValidationState.valid() : this._(ValidationStatus.valid, '');
  const ValidationState.invalid(String message)
      : this._(ValidationStatus.invalid, message);

  bool get isValid => status == ValidationStatus.valid;
  bool get isInvalid => status == ValidationStatus.invalid;
}

class ValidationIndicator extends StatelessWidget {
  final ValidationState state;

  const ValidationIndicator({Key? key, required this.state}) : super(key: key);

  void _showInvalidMessage(BuildContext context) {
    if (!state.isInvalid || state.message.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(state.message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (state.isValid) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (state.isInvalid) {
      return IconButton(
        icon: const Icon(Icons.error, color: Colors.redAccent),
        tooltip: state.message.isEmpty ? 'Invalid value' : state.message,
        onPressed: () => _showInvalidMessage(context),
      );
    }

    return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
  }
}

class ValidatedTextField extends StatelessWidget {
  final String label;
  final ValidationState state;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool enabled;
  final String? description;

  const ValidatedTextField({
    Key? key,
    required this.label,
    required this.state,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.hintText,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.enabled = true,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: ValidationIndicator(state: state),
      suffixIcon: description == null
          ? null
          : Tooltip(
              message: description!,
              child: const Icon(Icons.info_outline, size: 18),
            ),
    );

    if (controller != null) {
      return TextField(
        decoration: decoration,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        enabled: enabled,
      );
    }

    return TextFormField(
      decoration: decoration,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

class ValidatedDropdownField<T> extends StatelessWidget {
  final String label;
  final ValidationState state;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final String? description;

  const ValidatedDropdownField({
    Key? key,
    required this.label,
    required this.state,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: ValidationIndicator(state: state),
        suffixIcon: description == null
            ? null
            : Tooltip(
                message: description!,
                child: const Icon(Icons.info_outline, size: 18),
              ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}

class ValidatedCheckboxField extends StatelessWidget {
  final String label;
  final ValidationState state;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? description;

  const ValidatedCheckboxField({
    Key? key,
    required this.label,
    required this.state,
    required this.value,
    required this.onChanged,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Expanded(child: Text(label)),
          if (description != null)
            Tooltip(
              message: description!,
              child: const Icon(Icons.info_outline, size: 18),
            ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: ValidationIndicator(state: state),
      contentPadding: EdgeInsets.zero,
    );
  }
}
