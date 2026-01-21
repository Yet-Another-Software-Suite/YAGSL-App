import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/ui/config_page_layout.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class ControllerPropertiesPage extends StatelessWidget {
  ControllerPropertiesPage({Key? key}) : super(key: key);

  final List<TextInputFormatter> _numberFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
  ];

  ValidationState _validateRequiredNumber(String value, String label) {
    if (value.trim().isEmpty) {
      return ValidationState.invalid('Enter $label.');
    }
    final parsed = num.tryParse(value);
    if (parsed == null) {
      return ValidationState.invalid('$label must be a number.');
    }
    return const ValidationState.valid();
  }


  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heading Tuning'),
        actions: const [SettingsAction()],
      ),
      body: ConfigPageLayout(
        jsonTitle: 'controllerproperties.json',
        json: dataController.controllerPropertiesConfig.toJson(),
        form: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            ValidatedTextField(
              label: 'Joystick Radial Deadband',
              hintText: '0.0 - 1.0',
              state: dataController.validationFor(
                  'controller', 'angleJoystickRadiusDeadband'),
              initialValue: dataController.angleJoystickRadiusDeadband,
              description: 'Ignore small joystick magnitude changes.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleJoystickRadiusDeadband = value;
                dataController.updateValidation(
                  'controller',
                  'angleJoystickRadiusDeadband',
                  _validateRequiredNumber(value, 'Joystick Radial Deadband'),
                );
              },
            ),
            const Divider(height: 32.0),
            ValidatedTextField(
              label: 'Heading kP',
              hintText: 'Gain',
              state: dataController.validationFor('controller', 'headingP'),
              initialValue: dataController.headingP,
              description: 'Proportional gain for heading control.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.headingP = value;
                dataController.updateValidation(
                  'controller',
                  'headingP',
                  _validateRequiredNumber(value, 'Heading kP'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Heading kI',
              hintText: 'Gain',
              state: dataController.validationFor('controller', 'headingI'),
              initialValue: dataController.headingI,
              description: 'Integral gain for heading control.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.headingI = value;
                dataController.updateValidation(
                  'controller',
                  'headingI',
                  _validateRequiredNumber(value, 'Heading kI'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Heading kD',
              hintText: 'Gain',
              state: dataController.validationFor('controller', 'headingD'),
              initialValue: dataController.headingD,
              description: 'Derivative gain for heading control.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.headingD = value;
                dataController.updateValidation(
                  'controller',
                  'headingD',
                  _validateRequiredNumber(value, 'Heading kD'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
