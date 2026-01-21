import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/ui/config_page_layout.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class PhysicalPropertiesPage extends StatelessWidget {
  PhysicalPropertiesPage({Key? key}) : super(key: key);

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
        title: const Text('Module Properties'),
        actions: const [SettingsAction()],
      ),
      body: ConfigPageLayout(
        jsonTitle: 'physicalproperties.json',
        json: dataController.modulePropertiesConfig.toJson(),
        form: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const Text(
              'Conversion Factors',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedTextField(
              label: 'Angle/Steering/Azimuth Gear Ratio',
              hintText: 'Ratio',
              state: dataController.validationFor('physical', 'angleGearRatio'),
              initialValue: dataController.angleGearRatio,
              description: 'Total gear reduction for the angle motor.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.angleGearRatio = value;
                dataController.updateValidation(
                  'physical',
                  'angleGearRatio',
                  _validateRequiredNumber(value, 'Angle Gear Ratio'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive Gear Ratio',
              hintText: 'Ratio',
              state: dataController.validationFor('physical', 'driveGearRatio'),
              initialValue: dataController.driveGearRatio,
              description: 'Total gear reduction for the drive motor.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.driveGearRatio = value;
                dataController.updateValidation(
                  'physical',
                  'driveGearRatio',
                  _validateRequiredNumber(value, 'Drive Gear Ratio'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Wheel Diameter (in)',
              hintText: 'Inches',
              state: dataController.validationFor('physical', 'wheelDiameter'),
              initialValue: dataController.wheelDiameter,
              description: 'Wheel diameter used for drive distance conversion.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.wheelDiameter = value;
                dataController.updateValidation(
                  'physical',
                  'wheelDiameter',
                  _validateRequiredNumber(value, 'Wheel Diameter'),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Current Limits',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedTextField(
              label: 'Current Limit Drive',
              hintText: 'Amps',
              state: dataController.validationFor('physical', 'currentLimitDrive'),
              initialValue: dataController.currentLimitDrive,
              description: 'Drive motor current limit in amps.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.currentLimitDrive = value;
                dataController.updateValidation(
                  'physical',
                  'currentLimitDrive',
                  _validateRequiredNumber(value, 'Current Limit Drive'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Current Limit Angle',
              hintText: 'Amps',
              state: dataController.validationFor('physical', 'currentLimitAngle'),
              initialValue: dataController.currentLimitAngle,
              description: 'Angle motor current limit in amps.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.currentLimitAngle = value;
                dataController.updateValidation(
                  'physical',
                  'currentLimitAngle',
                  _validateRequiredNumber(value, 'Current Limit Angle'),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Ramp Rates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedTextField(
              label: 'Ramp Rate Drive',
              hintText: 'Seconds',
              state: dataController.validationFor('physical', 'rampRateDrive'),
              initialValue: dataController.rampRateDrive,
              description: 'Drive open-loop ramp time in seconds.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.rampRateDrive = value;
                dataController.updateValidation(
                  'physical',
                  'rampRateDrive',
                  _validateRequiredNumber(value, 'Ramp Rate Drive'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Ramp Rate Angle',
              hintText: 'Seconds',
              state: dataController.validationFor('physical', 'rampRateAngle'),
              initialValue: dataController.rampRateAngle,
              description: 'Angle open-loop ramp time in seconds.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.rampRateAngle = value;
                dataController.updateValidation(
                  'physical',
                  'rampRateAngle',
                  _validateRequiredNumber(value, 'Ramp Rate Angle'),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'General',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedTextField(
              label: 'Grip Coefficient of Friction',
              hintText: 'Coefficient',
              state: dataController.validationFor(
                  'physical', 'wheelGripCoefficientOfFriction'),
              initialValue: dataController.wheelGripCoefficientOfFriction,
              description: 'Wheel tread friction coefficient.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.wheelGripCoefficientOfFriction = value;
                dataController.updateValidation(
                  'physical',
                  'wheelGripCoefficientOfFriction',
                  _validateRequiredNumber(value, 'Grip Coefficient'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Robot Weight (in lbs)',
              hintText: 'Pounds',
              state: dataController.validationFor('physical', 'robotMass'),
              initialValue: dataController.robotMass,
              description: 'Robot weight used for traction estimates.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.robotMass = value;
                dataController.updateValidation(
                  'physical',
                  'robotMass',
                  _validateRequiredNumber(value, 'Robot Weight'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Optimal Voltage',
              hintText: 'Volts',
              state: dataController.validationFor('physical', 'optimalVoltage'),
              initialValue: dataController.optimalVoltage,
              description: 'Nominal voltage used for feedforward.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                dataController.optimalVoltage = value;
                dataController.updateValidation(
                  'physical',
                  'optimalVoltage',
                  _validateRequiredNumber(value, 'Optimal Voltage'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
