import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/configPages/config_options.dart';
import 'package:yagsl_app/ui/config_page_layout.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class ModuleConfigPage extends StatefulWidget {
  final String moduleKey;
  final String title;

  const ModuleConfigPage({
    Key? key,
    required this.moduleKey,
    required this.title,
  }) : super(key: key);

  @override
  State<ModuleConfigPage> createState() => _ModuleConfigPageState();
}

class _ModuleConfigPageState extends State<ModuleConfigPage> {
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

  ValidationState _validateRequiredSelect(String? value, String label) {
    if (value == null || value.isEmpty) {
      return ValidationState.invalid('Select $label.');
    }
    return const ValidationState.valid();
  }


  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    final module =
        dataController.modules[widget.moduleKey] ?? ModuleConfig();
    final locationFrontState =
        dataController.validationFor(widget.moduleKey, 'locationFront');
    final locationLeftState =
        dataController.validationFor(widget.moduleKey, 'locationLeft');
    final absoluteEncoderOffsetState =
        dataController.validationFor(widget.moduleKey, 'absoluteEncoderOffset');
    final driveTypeState =
        dataController.validationFor(widget.moduleKey, 'driveType');
    final driveIdState = dataController.validationFor(widget.moduleKey, 'driveId');
    final driveCanBusState =
        dataController.validationFor(widget.moduleKey, 'driveCanBus');
    final invertedDriveState =
        dataController.validationFor(widget.moduleKey, 'invertedDrive');
    final angleTypeState = dataController.validationFor(widget.moduleKey, 'angleType');
    final angleIdState = dataController.validationFor(widget.moduleKey, 'angleId');
    final angleCanBusState =
        dataController.validationFor(widget.moduleKey, 'angleCanBus');
    final invertedAngleState =
        dataController.validationFor(widget.moduleKey, 'invertedAngle');
    final encoderTypeState =
        dataController.validationFor(widget.moduleKey, 'encoderType');
    final encoderIdState = dataController.validationFor(widget.moduleKey, 'encoderId');
    final encoderCanBusState =
        dataController.validationFor(widget.moduleKey, 'encoderCanBus');
    final absoluteEncoderInvertedState =
        dataController.validationFor(widget.moduleKey, 'absoluteEncoderInverted');
    String? matchOption(String? value, List<String> options) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final lower = value.toLowerCase();
      for (final option in options) {
        if (option.toLowerCase() == lower) {
          return option;
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [SettingsAction()],
      ),
      body: ConfigPageLayout(
        jsonTitle: '${widget.moduleKey}.json',
        json: (dataController.moduleConfigs[widget.moduleKey]?.toJson() ??
            const <String, dynamic>{}),
        form: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const Text(
              'Drive',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedDropdownField<String>(
              label: 'Drive Motor Type',
              hintText: 'Select a motor',
              state: driveTypeState,
              value: matchOption(module.driveType, motorTypes),
              description: 'Motor/controller type for the drive motor.',
              items: motorTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                module.driveType = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'driveType',
                  _validateRequiredSelect(value, 'Drive Motor Type'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive Motor ID',
              hintText: '0-63',
              state: driveIdState,
              initialValue: module.driveId,
              description: 'CAN ID of the drive motor controller.',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                module.driveId = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'driveId',
                  _validateRequiredNumber(value, 'Drive Motor ID'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Drive Motor CAN Bus',
              hintText: 'Optional',
              state: driveCanBusState,
              initialValue: module.driveCanBus,
              description: 'CAN bus name for the drive motor.',
              onChanged: (value) {
                module.driveCanBus = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'driveCanBus',
                  const ValidationState.valid(),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedCheckboxField(
              label: 'Drive Motor Inverted',
              state: invertedDriveState,
              value: module.invertedDrive,
              description: 'Reverse drive motor direction.',
              onChanged: (value) {
                module.invertedDrive = value ?? false;
                dataController.updateValidation(
                  widget.moduleKey,
                  'invertedDrive',
                  const ValidationState.valid(),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Angle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedDropdownField<String>(
              label: 'Angle Motor Type',
              hintText: 'Select a motor',
              state: angleTypeState,
              value: matchOption(module.angleType, motorTypes),
              description: 'Motor/controller type for the steering motor.',
              items: motorTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                module.angleType = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'angleType',
                  _validateRequiredSelect(value, 'Angle Motor Type'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle Motor ID',
              hintText: '0-63',
              state: angleIdState,
              initialValue: module.angleId,
              description: 'CAN ID of the angle motor controller.',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                module.angleId = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'angleId',
                  _validateRequiredNumber(value, 'Angle Motor ID'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Angle Motor CAN Bus',
              hintText: 'Optional',
              state: angleCanBusState,
              initialValue: module.angleCanBus,
              description: 'CAN bus name for the angle motor.',
              onChanged: (value) {
                module.angleCanBus = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'angleCanBus',
                  const ValidationState.valid(),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedCheckboxField(
              label: 'Angle Motor Inverted',
              state: invertedAngleState,
              value: module.invertedAngle,
              description: 'Reverse steering motor direction.',
              onChanged: (value) {
                module.invertedAngle = value ?? false;
                dataController.updateValidation(
                  widget.moduleKey,
                  'invertedAngle',
                  const ValidationState.valid(),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Absolute Encoder',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedDropdownField<String>(
              label: 'Absolute Encoder Type',
              hintText: 'Select an encoder',
              state: encoderTypeState,
              value: matchOption(module.encoderType, encoderTypes),
              description: 'Absolute encoder hardware type.',
              items: encoderTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                module.encoderType = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'encoderType',
                  _validateRequiredSelect(value, 'Absolute Encoder Type'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Absolute Encoder ID',
              hintText: '0-63',
              state: encoderIdState,
              initialValue: module.encoderId,
              description: 'CAN ID of the absolute encoder.',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                module.encoderId = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'encoderId',
                  _validateRequiredNumber(value, 'Absolute Encoder ID'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Absolute Encoder CAN Bus',
              hintText: 'Optional',
              state: encoderCanBusState,
              initialValue: module.encoderCanBus,
              description: 'CAN bus name for the encoder.',
              onChanged: (value) {
                module.encoderCanBus = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'encoderCanBus',
                  const ValidationState.valid(),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedCheckboxField(
              label: 'Absolute Encoder Inverted',
              state: absoluteEncoderInvertedState,
              value: module.absoluteEncoderInverted,
              description: 'Reverse encoder direction.',
              onChanged: (value) {
                module.absoluteEncoderInverted = value ?? false;
                dataController.updateValidation(
                  widget.moduleKey,
                  'absoluteEncoderInverted',
                  const ValidationState.valid(),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedTextField(
              label: 'Absolute Encoder Offset',
              hintText: 'Coming soon',
              state: absoluteEncoderOffsetState,
              initialValue: module.absoluteEncoderOffset,
              description: 'Zero offset for absolute encoder angle.',
              enabled: false,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Location X',
              hintText: 'Inches (+x is towards robot front)',
              state: locationFrontState,
              initialValue: module.locationFront,
              description: 'Module X position from robot center.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                module.locationFront = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'locationFront',
                  _validateRequiredNumber(value, 'Location X'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'Location Y',
              hintText: 'Inches (+y is towards robot left)',
              state: locationLeftState,
              initialValue: module.locationLeft,
              description: 'Module Y position from robot center.',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              inputFormatters: _numberFormatters,
              onChanged: (value) {
                module.locationLeft = value;
                dataController.updateValidation(
                  widget.moduleKey,
                  'locationLeft',
                  _validateRequiredNumber(value, 'Location Y'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
