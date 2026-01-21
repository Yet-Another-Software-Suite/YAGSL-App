import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/configPages/config_options.dart';
import 'package:yagsl_app/ui/config_page_layout.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class SwerveDriveConfigPage extends StatelessWidget {
  const SwerveDriveConfigPage({Key? key}) : super(key: key);

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

  ValidationState _validateImuType(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationState.invalid('Pick an IMU type.');
    }
    return const ValidationState.valid();
  }


  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    final imuTypeState = dataController.validationFor('swervedrive', 'imuType');
    final imuIdState = dataController.validationFor('swervedrive', 'imuId');
    final imuCanBusState =
        dataController.validationFor('swervedrive', 'imuCanBus');
    final invertedImuState =
        dataController.validationFor('swervedrive', 'invertedImu');
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
        title: const Text('Swerve Drive'),
        actions: const [SettingsAction()],
      ),
      body: ConfigPageLayout(
        jsonTitle: 'swervedrive.json',
        json: dataController.swerveDriveConfig.toJson(),
        form: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const Text(
              'IMU',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ValidatedDropdownField<String>(
              label: 'IMU Type',
              hintText: 'Select an IMU',
              state: imuTypeState,
              value: matchOption(dataController.imuType, imuTypes),
              description: 'Gyro/IMU model used for heading.',
              items: imuTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                dataController.imuType = value;
                dataController.updateValidation(
                  'swervedrive',
                  'imuType',
                  _validateImuType(value),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'IMU ID',
              hintText: '0-63',
              state: imuIdState,
              initialValue: dataController.imuId,
              description: 'CAN ID of the IMU device.',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                dataController.imuId = value;
                dataController.updateValidation(
                  'swervedrive',
                  'imuId',
                  _validateRequiredNumber(value, 'IMU ID'),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedTextField(
              label: 'IMU CAN Bus',
              hintText: 'Optional',
              state: imuCanBusState,
              initialValue: dataController.imuCanBus,
              description: 'CAN bus name, leave blank for default bus.',
              onChanged: (value) {
                dataController.imuCanBus = value;
                dataController.updateValidation(
                  'swervedrive',
                  'imuCanBus',
                  const ValidationState.valid(),
                );
              },
            ),
            const SizedBox(height: 12.0),
            ValidatedCheckboxField(
              label: 'Inverted IMU',
              state: invertedImuState,
              value: dataController.invertedImu,
              description: 'Reverse IMU yaw direction.',
              onChanged: (value) {
                dataController.invertedImu = value ?? false;
                dataController.updateValidation(
                  'swervedrive',
                  'invertedImu',
                  const ValidationState.valid(),
                );
              },
            ),
            const Divider(height: 32.0),
            const Text(
              'Modules',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'frontleft.json, frontright.json, backleft.json, backright.json',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
