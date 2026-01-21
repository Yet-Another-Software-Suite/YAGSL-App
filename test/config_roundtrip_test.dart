import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yagsl_app/DataController.dart';

Future<void> _writeSwerveFiles(
  Directory root,
  Map<String, String> files,
) async {
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key}');
    await file.create(recursive: true);
    await file.writeAsString(entry.value);
  }
}

String _normalizeNumber(String value) {
  final parsed = double.tryParse(value);
  if (parsed == null) {
    return value;
  }
  if (parsed == parsed.roundToDouble()) {
    return parsed.toInt().toString();
  }
  return parsed.toString();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('config export/import roundtrip preserves values', () async {
    final source = DataController();
    source.imuType = 'Pigeon2';
    source.imuId = '5';
    source.imuCanBus = 'rio';
    source.invertedImu = true;

    source.optimalVoltage = '12';
    source.robotMass = '52.3';
    source.wheelGripCoefficientOfFriction = '1.2';
    source.currentLimitDrive = '35';
    source.currentLimitAngle = '25';
    source.angleGearRatio = '12.8';
    source.wheelDiameter = '4.0';
    source.driveGearRatio = '6.75';
    source.rampRateDrive = '0.25';
    source.rampRateAngle = '0.3';

    source.angleJoystickRadiusDeadband = '0.4';
    source.headingP = '0.5';
    source.headingI = '0.01';
    source.headingD = '0.02';

    source.driveP = '0.1';
    source.driveI = '0.2';
    source.driveD = '0.3';
    source.driveF = '0.4';
    source.driveIZ = '0.5';
    source.angleP = '0.6';
    source.angleI = '0.7';
    source.angleD = '0.8';
    source.angleF = '0.9';
    source.angleIZ = '1.0';

    source.modules['frontleft']!
      ..locationFront = '10'
      ..locationLeft = '20'
      ..absoluteEncoderOffset = '3.14'
      ..driveType = 'NEO (via SparkMAX)'
      ..driveId = '11'
      ..driveCanBus = 'rio'
      ..invertedDrive = true
      ..angleType = 'NEO (via SparkMAX)'
      ..angleId = '12'
      ..angleCanBus = 'rio'
      ..invertedAngle = true
      ..encoderType = 'CANCoder'
      ..encoderId = '13'
      ..encoderCanBus = 'rio'
      ..absoluteEncoderInverted = true;

    source.modules['frontright']!
      ..locationFront = '11'
      ..locationLeft = '21'
      ..absoluteEncoderOffset = '2.71'
      ..driveType = 'Falcon500'
      ..driveId = '21'
      ..driveCanBus = ''
      ..invertedDrive = false
      ..angleType = 'Falcon500'
      ..angleId = '22'
      ..angleCanBus = ''
      ..invertedAngle = false
      ..encoderType = 'REV Through Bore (DIO)'
      ..encoderId = '23'
      ..encoderCanBus = ''
      ..absoluteEncoderInverted = false;

    final files = source.buildSwerveConfigJson();
    final tempDir = await Directory.systemTemp.createTemp('yagsl_test_');
    final swerveDir = Directory('${tempDir.path}/swerve');
    await swerveDir.create(recursive: true);
    await _writeSwerveFiles(tempDir, files);

    final target = DataController();
    await target.importFromSwerveDirectory(swerveDir.path);

    expect(target.imuType, source.imuType);
    expect(target.imuId, source.imuId);
    expect(target.imuCanBus, source.imuCanBus);
    expect(target.invertedImu, source.invertedImu);

    expect(target.optimalVoltage, source.optimalVoltage);
    expect(target.robotMass, source.robotMass);
    expect(
      target.wheelGripCoefficientOfFriction,
      source.wheelGripCoefficientOfFriction,
    );
    expect(target.currentLimitDrive, source.currentLimitDrive);
    expect(target.currentLimitAngle, source.currentLimitAngle);
    expect(target.angleGearRatio, source.angleGearRatio);
    expect(target.wheelDiameter, source.wheelDiameter);
    expect(target.driveGearRatio, source.driveGearRatio);
    expect(target.rampRateDrive, source.rampRateDrive);
    expect(target.rampRateAngle, source.rampRateAngle);

    final targetFrontLeft = target.modules['frontleft']!;
    expect(
      _normalizeNumber(targetFrontLeft.locationFront),
      _normalizeNumber(source.modules['frontleft']!.locationFront),
    );
    expect(
      _normalizeNumber(targetFrontLeft.locationLeft),
      _normalizeNumber(source.modules['frontleft']!.locationLeft),
    );
    expect(
      _normalizeNumber(targetFrontLeft.absoluteEncoderOffset),
      _normalizeNumber(source.modules['frontleft']!.absoluteEncoderOffset),
    );
    expect(targetFrontLeft.driveType, source.modules['frontleft']!.driveType);
    expect(targetFrontLeft.driveId, source.modules['frontleft']!.driveId);
    expect(targetFrontLeft.driveCanBus, source.modules['frontleft']!.driveCanBus);
    expect(targetFrontLeft.invertedDrive, source.modules['frontleft']!.invertedDrive);
    expect(targetFrontLeft.angleType, source.modules['frontleft']!.angleType);
    expect(targetFrontLeft.angleId, source.modules['frontleft']!.angleId);
    expect(targetFrontLeft.angleCanBus, source.modules['frontleft']!.angleCanBus);
    expect(targetFrontLeft.invertedAngle, source.modules['frontleft']!.invertedAngle);
    expect(targetFrontLeft.encoderType, source.modules['frontleft']!.encoderType);
    expect(targetFrontLeft.encoderId, source.modules['frontleft']!.encoderId);
    expect(targetFrontLeft.encoderCanBus, source.modules['frontleft']!.encoderCanBus);
    expect(
      targetFrontLeft.absoluteEncoderInverted,
      source.modules['frontleft']!.absoluteEncoderInverted,
    );

    await tempDir.delete(recursive: true);
  });
}
