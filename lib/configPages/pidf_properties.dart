import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/ui/config_page_layout.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class PidfPropertiesPage extends StatelessWidget {
  PidfPropertiesPage({Key? key}) : super(key: key);

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
        title: const Text('Module Tuning'),
        actions: const [SettingsAction()],
      ),
      body: ConfigPageLayout(
        jsonTitle: 'pidfproperties.json',
        json: dataController.pidfPropertiesConfig.toJson(),
        form: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            ValidatedTextField(
              label: 'Drive kP',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'driveP'),
              initialValue: dataController.driveP,
              description: 'Drive proportional gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveP = value;
                dataController.updateValidation(
                  'pidf',
                  'driveP',
                  _validateRequiredNumber(value, 'Drive kP'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive kI',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'driveI'),
              initialValue: dataController.driveI,
              description: 'Drive integral gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveI = value;
                dataController.updateValidation(
                  'pidf',
                  'driveI',
                  _validateRequiredNumber(value, 'Drive kI'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive kD',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'driveD'),
              initialValue: dataController.driveD,
              description: 'Drive derivative gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveD = value;
                dataController.updateValidation(
                  'pidf',
                  'driveD',
                  _validateRequiredNumber(value, 'Drive kD'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive kF',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'driveF'),
              initialValue: dataController.driveF,
              description: 'Drive feedforward gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveF = value;
                dataController.updateValidation(
                  'pidf',
                  'driveF',
                  _validateRequiredNumber(value, 'Drive kF'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive Integral Zone',
              hintText: 'IZone',
              state: dataController.validationFor('pidf', 'driveIZ'),
              initialValue: dataController.driveIZ,
              description: 'Drive integral zone limit.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveIZ = value;
                dataController.updateValidation(
                  'pidf',
                  'driveIZ',
                  _validateRequiredNumber(value, 'Drive Integral Zone'),
                );
              },
            ),
            const Divider(height: 32.0),
            ValidatedTextField(
              label: 'Angle kP',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'angleP'),
              initialValue: dataController.angleP,
              description: 'Angle proportional gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleP = value;
                dataController.updateValidation(
                  'pidf',
                  'angleP',
                  _validateRequiredNumber(value, 'Angle kP'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle kI',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'angleI'),
              initialValue: dataController.angleI,
              description: 'Angle integral gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleI = value;
                dataController.updateValidation(
                  'pidf',
                  'angleI',
                  _validateRequiredNumber(value, 'Angle kI'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle kD',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'angleD'),
              initialValue: dataController.angleD,
              description: 'Angle derivative gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleD = value;
                dataController.updateValidation(
                  'pidf',
                  'angleD',
                  _validateRequiredNumber(value, 'Angle kD'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle kF',
              hintText: 'Gain',
              state: dataController.validationFor('pidf', 'angleF'),
              initialValue: dataController.angleF,
              description: 'Angle feedforward gain.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleF = value;
                dataController.updateValidation(
                  'pidf',
                  'angleF',
                  _validateRequiredNumber(value, 'Angle kF'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle Integral Zone',
              hintText: 'IZone',
              state: dataController.validationFor('pidf', 'angleIZ'),
              initialValue: dataController.angleIZ,
              description: 'Angle integral zone limit.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleIZ = value;
                dataController.updateValidation(
                  'pidf',
                  'angleIZ',
                  _validateRequiredNumber(value, 'Angle Integral Zone'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
