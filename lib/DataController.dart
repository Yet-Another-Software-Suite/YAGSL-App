import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yagsl_app/jsonContruction/angle.dart';
import 'package:yagsl_app/jsonContruction/angle_tuning.dart';
import 'package:yagsl_app/jsonContruction/controller_properties.dart';
import 'package:yagsl_app/jsonContruction/conversion_factor.dart';
import 'package:yagsl_app/jsonContruction/current_limit.dart';
import 'package:yagsl_app/jsonContruction/drive.dart';
import 'package:yagsl_app/jsonContruction/drive_tuning.dart';
import 'package:yagsl_app/jsonContruction/imu.dart';
import 'package:yagsl_app/jsonContruction/inverted.dart';
import 'package:yagsl_app/jsonContruction/location.dart';
import 'package:yagsl_app/jsonContruction/module.dart';
import 'package:yagsl_app/jsonContruction/module_encoder.dart';
import 'package:yagsl_app/jsonContruction/module_properties.dart';
import 'package:yagsl_app/jsonContruction/pidf_properties.dart';
import 'package:yagsl_app/jsonContruction/ramp_rate.dart';
import 'package:yagsl_app/jsonContruction/swerve_drive.dart';
import 'package:yagsl_app/services/connection_status.dart';
import 'package:yagsl_app/ui/validation.dart';

class DataController with ChangeNotifier {
  static const _configStorageKey = 'robot_config_state';

  DataController() {
    _rebuildConfigObjects();
  }

  //Data
  int teamNumber = 0;
  SwerveDrive swerveDriveConfig =
      SwerveDrive(Imu('pigeon', 0, null), false);
  ModuleProperties modulePropertiesConfig = ModuleProperties(
    ConversionFactors(
      AngleConversionFactor(0, 0),
      DriveConversionFactor(0, 0, 0),
    ),
    CurrentLimit(0, 0),
    RampRate(0, 0),
    0,
    0,
    0,
  );
  ControllerProperties controllerPropertiesConfig =
      ControllerProperties(0.5, Heading(0.4, 0, 0.01));
  PIDFProperties pidfPropertiesConfig = PIDFProperties(
    DriveTuning(0.00023, 0.0000002, 1.0, 0, 0),
    AngleTuning(0.01, 0, 0, 0, 0),
  );
  final Map<String, Module> moduleConfigs = {};
  String? imuType;
  String imuId = '';
  String imuCanBus = '';
  bool invertedImu = false;

  ConnectionStatus nt4Status = ConnectionStatus.disconnected;

  String optimalVoltage = '';
  String robotMass = '';
  String wheelGripCoefficientOfFriction = '';
  String currentLimitDrive = '';
  String currentLimitAngle = '';
  String angleGearRatio = '';
  String wheelDiameter = '';
  String driveGearRatio = '';
  String rampRateDrive = '';
  String rampRateAngle = '';

  String angleJoystickRadiusDeadband = '0.5';
  String headingP = '0.4';
  String headingI = '0';
  String headingD = '0.01';

  String driveP = '0.0020645';
  String driveI = '0';
  String driveD = '0';
  String driveF = '0';
  String driveIZ = '0';
  String angleP = '0.0020645';
  String angleI = '0';
  String angleD = '0';
  String angleF = '0';
  String angleIZ = '0';

  final Map<String, ModuleConfig> modules = {
    'frontleft': ModuleConfig(),
    'frontright': ModuleConfig(),
    'backleft': ModuleConfig(),
    'backright': ModuleConfig(),
  };

  final Map<String, Map<String, ValidationState>> _menuValidations =
      _defaultValidations();

  final Map<String, Set<String>> _optionalFields = {
    'swervedrive': {'imuCanBus'},
    'physical': {},
    'frontleft': {
      'absoluteEncoderOffset',
      'driveCanBus',
      'angleCanBus',
      'encoderCanBus'
    },
    'frontright': {
      'absoluteEncoderOffset',
      'driveCanBus',
      'angleCanBus',
      'encoderCanBus'
    },
    'backleft': {
      'absoluteEncoderOffset',
      'driveCanBus',
      'angleCanBus',
      'encoderCanBus'
    },
    'backright': {
      'absoluteEncoderOffset',
      'driveCanBus',
      'angleCanBus',
      'encoderCanBus'
    },
  };

  void setTeamNumber(int value) {
    teamNumber = value;
    _save();
    notifyListeners();
  }

  void setNt4Status(ConnectionStatus status) {
    nt4Status = status;
    notifyListeners();
  }

  ValidationState validationFor(String menuKey, String fieldKey) {
    return _menuValidations[menuKey]?[fieldKey] ??
        const ValidationState.unknown();
  }

  void updateValidation(
    String menuKey,
    String fieldKey,
    ValidationState state,
  ) {
    final menu = _menuValidations[menuKey];
    if (menu == null) {
      return;
    }
    menu[fieldKey] = state;
    _rebuildConfigObjects();
    _save();
    notifyListeners();
  }

  bool isMenuComplete(String menuKey) {
    final menu = _menuValidations[menuKey];
    if (menu == null || menu.isEmpty) {
      return false;
    }
    final optional = _optionalFields[menuKey] ?? {};
    for (final entry in menu.entries) {
      if (optional.contains(entry.key) &&
          entry.value.status == ValidationStatus.unknown) {
        continue;
      }
      if (entry.value.status != ValidationStatus.valid) {
        return false;
      }
    }
    return true;
  }

  bool isConfigComplete() {
    for (final key in _menuValidations.keys) {
      if (!isMenuComplete(key)) {
        return false;
      }
    }
    return true;
  }

  Map<String, String> buildSwerveConfigJson() {
    _rebuildConfigObjects();
    final encoder = JsonEncoder.withIndent('  ');
    final files = <String, String>{};
    files['swerve/controllerproperties.json'] =
        encoder.convert(controllerPropertiesConfig.toJson());
    files['swerve/swervedrive.json'] =
        encoder.convert(swerveDriveConfig.toJson());
    files['swerve/modules/physicalproperties.json'] =
        encoder.convert(modulePropertiesConfig.toJson());
    files['swerve/modules/pidfproperties.json'] =
        encoder.convert(pidfPropertiesConfig.toJson());

    for (final key in const [
      'frontleft',
      'frontright',
      'backleft',
      'backright',
    ]) {
      final module = moduleConfigs[key];
      if (module == null) {
        throw StateError('Missing module config for $key');
      }
      files['swerve/modules/$key.json'] = encoder.convert(module.toJson());
    }
    return files;
  }

  Future<void> writeSwerveDeployFiles(String projectRoot) async {
    final files = buildSwerveConfigJson();
    final deployRoot = Directory('$projectRoot/src/main/deploy');
    for (final entry in files.entries) {
      final filePath = '${deployRoot.path}/${entry.key}';
      final file = File(filePath);
      file.createSync(recursive: true);
      await file.writeAsString(entry.value);
    }
  }

  Future<void> importFromSwerveDirectory(String rootPath) async {
    Map<String, dynamic> readJson(String relativePath) {
      final file = File('$rootPath/$relativePath');
      if (!file.existsSync()) {
        throw StateError('Missing config file: ${file.path}');
      }
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    final swervedrive =
        SwerveDrive.fromJson(readJson('swervedrive.json'));
    final controller =
        ControllerProperties.fromJson(readJson('controllerproperties.json'));
    final physical =
        ModuleProperties.fromJson(readJson('modules/physicalproperties.json'));
    final pidf =
        PIDFProperties.fromJson(readJson('modules/pidfproperties.json'));

    imuType = swervedrive.imu.type;
    imuId = swervedrive.imu.id.toString();
    imuCanBus = swervedrive.imu.canbus ?? '';
    invertedImu = swervedrive.invertedIMU;

    angleJoystickRadiusDeadband =
        controller.angleJoystickRadiusDeadband.toString();
    headingP = controller.heading.p.toString();
    headingI = controller.heading.i.toString();
    headingD = controller.heading.d.toString();

    angleGearRatio = physical.conversionFactors.angle.gearRatio.toString();
    driveGearRatio = physical.conversionFactors.drive.gearRatio.toString();
    wheelDiameter = physical.conversionFactors.drive.diameter.toString();
    currentLimitDrive = physical.currentLimit.drive.toString();
    currentLimitAngle = physical.currentLimit.angle.toString();
    rampRateDrive = physical.rampRate.drive.toString();
    rampRateAngle = physical.rampRate.angle.toString();
    optimalVoltage = physical.optimalVoltage.toString();
    robotMass = physical.robotMass.toString();
    wheelGripCoefficientOfFriction =
        physical.wheelGripCoefficientOfFriction.toString();

    driveP = pidf.drive.p.toString();
    driveI = pidf.drive.i.toString();
    driveD = pidf.drive.d.toString();
    driveF = pidf.drive.f.toString();
    driveIZ = pidf.drive.iz.toString();
    angleP = pidf.angle.p.toString();
    angleI = pidf.angle.i.toString();
    angleD = pidf.angle.d.toString();
    angleF = pidf.angle.f.toString();
    angleIZ = pidf.angle.iz.toString();

    final moduleFiles = {
      'frontleft': 'modules/frontleft.json',
      'frontright': 'modules/frontright.json',
      'backleft': 'modules/backleft.json',
      'backright': 'modules/backright.json',
    };
    moduleFiles.forEach((key, path) {
      final module = Module.fromJson(readJson(path));
      final config = modules[key];
      if (config == null) {
        return;
      }
      config.locationFront = module.location.front.toString();
      config.locationLeft = module.location.left.toString();
      config.absoluteEncoderOffset = module.absoluteEncoderOffset.toString();
      config.driveType = module.drive.type;
      config.driveId = module.drive.id.toString();
      config.driveCanBus = module.drive.canbus ?? '';
      config.invertedDrive = module.inverted.drive;
      config.angleType = module.angle.type;
      config.angleId = module.angle.id.toString();
      config.angleCanBus = module.angle.canbus ?? '';
      config.invertedAngle = module.inverted.angle;
      config.encoderType = module.encoder.type;
      config.encoderId = module.encoder.id.toString();
      config.encoderCanBus = module.encoder.canbus ?? '';
      config.absoluteEncoderInverted =
          module.absoluteEncoderInverted ?? false;
    });

    _rebuildConfigObjects();
    _refreshValidationsFromValues();
    await _save();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_configStorageKey);
    if (payload == null || payload.isEmpty) {
      return;
    }
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    teamNumber = decoded['teamNumber'] as int? ?? 0;
    imuType = decoded['imuType'] as String?;
    imuId = decoded['imuId'] as String? ?? '';
    imuCanBus = decoded['imuCanBus'] as String? ?? '';
    invertedImu = decoded['invertedImu'] as bool? ?? false;

    optimalVoltage = decoded['optimalVoltage'] as String? ?? '';
    robotMass = decoded['robotMass'] as String? ?? '';
    wheelGripCoefficientOfFriction =
        decoded['wheelGripCoefficientOfFriction'] as String? ?? '';
    currentLimitDrive = decoded['currentLimitDrive'] as String? ?? '';
    currentLimitAngle = decoded['currentLimitAngle'] as String? ?? '';
    angleGearRatio = decoded['angleGearRatio'] as String? ?? '';
    wheelDiameter = decoded['wheelDiameter'] as String? ?? '';
    driveGearRatio = decoded['driveGearRatio'] as String? ?? '';
    rampRateDrive = decoded['rampRateDrive'] as String? ?? '';
    rampRateAngle = decoded['rampRateAngle'] as String? ?? '';

    angleJoystickRadiusDeadband =
        decoded['angleJoystickRadiusDeadband'] as String? ??
            angleJoystickRadiusDeadband;
    headingP = decoded['headingP'] as String? ?? headingP;
    headingI = decoded['headingI'] as String? ?? headingI;
    headingD = decoded['headingD'] as String? ?? headingD;

    driveP = decoded['driveP'] as String? ?? driveP;
    driveI = decoded['driveI'] as String? ?? driveI;
    driveD = decoded['driveD'] as String? ?? driveD;
    driveF = decoded['driveF'] as String? ?? driveF;
    driveIZ = decoded['driveIZ'] as String? ?? driveIZ;
    angleP = decoded['angleP'] as String? ?? angleP;
    angleI = decoded['angleI'] as String? ?? angleI;
    angleD = decoded['angleD'] as String? ?? angleD;
    angleF = decoded['angleF'] as String? ?? angleF;
    angleIZ = decoded['angleIZ'] as String? ?? angleIZ;

    final modulePayload = decoded['modules'] as Map<String, dynamic>? ?? {};
    modules.forEach((key, module) {
      final moduleJson = modulePayload[key] as Map<String, dynamic>? ?? {};
      module.locationFront = moduleJson['locationFront'] as String? ?? '0';
      module.locationLeft = moduleJson['locationLeft'] as String? ?? '0';
      module.absoluteEncoderOffset =
          moduleJson['absoluteEncoderOffset'] as String? ?? '0';
      module.driveType = moduleJson['driveType'] as String?;
      module.driveId = moduleJson['driveId'] as String? ?? '0';
      module.driveCanBus = moduleJson['driveCanBus'] as String? ?? '';
      module.invertedDrive = moduleJson['invertedDrive'] as bool? ?? false;
      module.angleType = moduleJson['angleType'] as String?;
      module.angleId = moduleJson['angleId'] as String? ?? '0';
      module.angleCanBus = moduleJson['angleCanBus'] as String? ?? '';
      module.invertedAngle = moduleJson['invertedAngle'] as bool? ?? false;
      module.encoderType = moduleJson['encoderType'] as String?;
      module.encoderId = moduleJson['encoderId'] as String? ?? '0';
      module.encoderCanBus = moduleJson['encoderCanBus'] as String? ?? '';
      module.absoluteEncoderInverted =
          moduleJson['absoluteEncoderInverted'] as bool? ?? false;
    });

    _rebuildConfigObjects();
    _refreshValidationsFromValues();
    notifyListeners();
  }

  void resetRobotConfigs() {
    imuType = null;
    imuId = '';
    imuCanBus = '';
    invertedImu = false;

    optimalVoltage = '';
    robotMass = '';
    wheelGripCoefficientOfFriction = '';
    currentLimitDrive = '';
    currentLimitAngle = '';
    angleGearRatio = '';
    wheelDiameter = '';
    driveGearRatio = '';
    rampRateDrive = '';
    rampRateAngle = '';

    angleJoystickRadiusDeadband = '0.5';
    headingP = '0.4';
    headingI = '0';
    headingD = '0.01';

    driveP = '0.0020645';
    driveI = '0';
    driveD = '0';
    driveF = '0';
    driveIZ = '0';
    angleP = '0.0020645';
    angleI = '0';
    angleD = '0';
    angleF = '0';
    angleIZ = '0';

    modules.forEach((_, module) {
      module.locationFront = '0';
      module.locationLeft = '0';
      module.absoluteEncoderOffset = '0';
      module.driveType = null;
      module.driveId = '0';
      module.driveCanBus = '';
      module.invertedDrive = false;
      module.angleType = null;
      module.angleId = '0';
      module.angleCanBus = '';
      module.invertedAngle = false;
      module.encoderType = null;
      module.encoderId = '0';
      module.encoderCanBus = '';
      module.absoluteEncoderInverted = false;
    });

    _menuValidations
      ..clear()
      ..addAll(_defaultValidations());
    _rebuildConfigObjects();
    _save();
    notifyListeners();
  }

  void _rebuildConfigObjects() {
    final imuIdValue = _parseInt(imuId);
    final imu = Imu(imuType ?? '', imuIdValue, _nullIfEmpty(imuCanBus));
    swerveDriveConfig = SwerveDrive(imu, invertedImu);
    swerveDriveConfig.schema = null;

    final conversionFactors = ConversionFactors(
      AngleConversionFactor(_parseDouble(angleGearRatio), 0),
      DriveConversionFactor(
        _parseDouble(driveGearRatio),
        _parseDouble(wheelDiameter),
        0,
      ),
    );
    modulePropertiesConfig = ModuleProperties(
      conversionFactors,
      CurrentLimit(
        _parseInt(currentLimitDrive),
        _parseInt(currentLimitAngle),
      ),
      RampRate(
        _parseDouble(rampRateDrive),
        _parseDouble(rampRateAngle),
      ),
      _parseInt(optimalVoltage),
      _parseDouble(robotMass),
      _parseDouble(wheelGripCoefficientOfFriction),
    );

    controllerPropertiesConfig = ControllerProperties(
      _parseDouble(angleJoystickRadiusDeadband),
      Heading(
        _parseDouble(headingP),
        _parseDouble(headingI),
        _parseDouble(headingD),
      ),
    );

    pidfPropertiesConfig = PIDFProperties(
      DriveTuning(
        _parseDouble(driveP),
        _parseDouble(driveI),
        _parseDouble(driveD),
        _parseDouble(driveF),
        _parseDouble(driveIZ),
      ),
      AngleTuning(
        _parseDouble(angleP),
        _parseDouble(angleI),
        _parseDouble(angleD),
        _parseDouble(angleF),
        _parseDouble(angleIZ),
      ),
    );

    moduleConfigs.clear();
    modules.forEach((key, module) {
      final moduleJson = Module(
        Location(
          _parseDouble(module.locationFront),
          _parseDouble(module.locationLeft),
        ),
        _parseDouble(module.absoluteEncoderOffset),
        Drive(
          module.driveType ?? '',
          _parseInt(module.driveId),
          _nullIfEmpty(module.driveCanBus),
        ),
        Angle(
          module.angleType ?? '',
          _parseInt(module.angleId),
          _nullIfEmpty(module.angleCanBus),
          null,
        ),
        ModuleEncoder(
          module.encoderType ?? '',
          _parseInt(module.encoderId),
          _nullIfEmpty(module.encoderCanBus),
        ),
        Inverted(module.invertedDrive, module.invertedAngle),
        module.absoluteEncoderInverted,
      );
      moduleConfigs[key] = moduleJson;
    });
  }

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0;

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  Map<String, dynamic> _toPersistedJson() {
    return {
      'teamNumber': teamNumber,
      'imuType': imuType,
      'imuId': imuId,
      'imuCanBus': imuCanBus,
      'invertedImu': invertedImu,
      'optimalVoltage': optimalVoltage,
      'robotMass': robotMass,
      'wheelGripCoefficientOfFriction': wheelGripCoefficientOfFriction,
      'currentLimitDrive': currentLimitDrive,
      'currentLimitAngle': currentLimitAngle,
      'angleGearRatio': angleGearRatio,
      'wheelDiameter': wheelDiameter,
      'driveGearRatio': driveGearRatio,
      'rampRateDrive': rampRateDrive,
      'rampRateAngle': rampRateAngle,
      'angleJoystickRadiusDeadband': angleJoystickRadiusDeadband,
      'headingP': headingP,
      'headingI': headingI,
      'headingD': headingD,
      'driveP': driveP,
      'driveI': driveI,
      'driveD': driveD,
      'driveF': driveF,
      'driveIZ': driveIZ,
      'angleP': angleP,
      'angleI': angleI,
      'angleD': angleD,
      'angleF': angleF,
      'angleIZ': angleIZ,
      'modules': modules.map((key, module) => MapEntry(key, module.toJson())),
    };
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configStorageKey, jsonEncode(_toPersistedJson()));
  }

  void _refreshValidationsFromValues() {
    void mark(String menu, String key, bool hasValue) {
      if (!_menuValidations.containsKey(menu) ||
          !_menuValidations[menu]!.containsKey(key)) {
        return;
      }
      _menuValidations[menu]![key] =
          hasValue ? const ValidationState.valid() : const ValidationState.unknown();
    }

    mark('swervedrive', 'imuType', (imuType ?? '').isNotEmpty);
    mark('swervedrive', 'imuId', imuId.isNotEmpty);
    mark('main', 'teamNumber', teamNumber >= 0);
    mark('physical', 'optimalVoltage', optimalVoltage.isNotEmpty);
    mark('physical', 'robotMass', robotMass.isNotEmpty);
    mark('physical', 'wheelGripCoefficientOfFriction',
        wheelGripCoefficientOfFriction.isNotEmpty);
    mark('physical', 'currentLimitDrive', currentLimitDrive.isNotEmpty);
    mark('physical', 'currentLimitAngle', currentLimitAngle.isNotEmpty);
    mark('physical', 'angleGearRatio', angleGearRatio.isNotEmpty);
    mark('physical', 'wheelDiameter', wheelDiameter.isNotEmpty);
    mark('physical', 'driveGearRatio', driveGearRatio.isNotEmpty);
    mark('physical', 'rampRateDrive', rampRateDrive.isNotEmpty);
    mark('physical', 'rampRateAngle', rampRateAngle.isNotEmpty);

    modules.forEach((key, module) {
      mark(key, 'locationFront', module.locationFront.isNotEmpty);
      mark(key, 'locationLeft', module.locationLeft.isNotEmpty);
      mark(key, 'driveType', (module.driveType ?? '').isNotEmpty);
      mark(key, 'driveId', module.driveId.isNotEmpty);
      mark(key, 'angleType', (module.angleType ?? '').isNotEmpty);
      mark(key, 'angleId', module.angleId.isNotEmpty);
      mark(key, 'encoderType', (module.encoderType ?? '').isNotEmpty);
      mark(key, 'encoderId', module.encoderId.isNotEmpty);
    });
  }
}

Map<String, Map<String, ValidationState>> _defaultValidations() {
  return {
    'main': {
      'teamNumber': const ValidationState.unknown(),
    },
    'swervedrive': {
      'imuType': const ValidationState.unknown(),
      'imuId': const ValidationState.unknown(),
      'imuCanBus': const ValidationState.valid(),
      'invertedImu': const ValidationState.valid(),
    },
    'physical': {
      'optimalVoltage': const ValidationState.unknown(),
      'robotMass': const ValidationState.unknown(),
      'wheelGripCoefficientOfFriction': const ValidationState.unknown(),
      'currentLimitDrive': const ValidationState.unknown(),
      'currentLimitAngle': const ValidationState.unknown(),
      'angleGearRatio': const ValidationState.unknown(),
      'wheelDiameter': const ValidationState.unknown(),
      'driveGearRatio': const ValidationState.unknown(),
      'rampRateDrive': const ValidationState.unknown(),
      'rampRateAngle': const ValidationState.unknown(),
    },
    'frontleft': _defaultModuleValidations(),
    'frontright': _defaultModuleValidations(),
    'backleft': _defaultModuleValidations(),
    'backright': _defaultModuleValidations(),
    'controller': {
      'angleJoystickRadiusDeadband': const ValidationState.valid(),
      'headingP': const ValidationState.valid(),
      'headingI': const ValidationState.valid(),
      'headingD': const ValidationState.valid(),
    },
    'pidf': {
      'driveP': const ValidationState.valid(),
      'driveI': const ValidationState.valid(),
      'driveD': const ValidationState.valid(),
      'driveF': const ValidationState.valid(),
      'driveIZ': const ValidationState.valid(),
      'angleP': const ValidationState.valid(),
      'angleI': const ValidationState.valid(),
      'angleD': const ValidationState.valid(),
      'angleF': const ValidationState.valid(),
      'angleIZ': const ValidationState.valid(),
    },
  };
}

Map<String, ValidationState> _defaultModuleValidations() {
  return {
    'locationFront': const ValidationState.unknown(),
    'locationLeft': const ValidationState.unknown(),
    'absoluteEncoderOffset': const ValidationState.valid(),
    'driveType': const ValidationState.unknown(),
    'driveId': const ValidationState.unknown(),
    'driveCanBus': const ValidationState.valid(),
    'invertedDrive': const ValidationState.valid(),
    'angleType': const ValidationState.unknown(),
    'angleId': const ValidationState.unknown(),
    'angleCanBus': const ValidationState.valid(),
    'invertedAngle': const ValidationState.valid(),
    'encoderType': const ValidationState.unknown(),
    'encoderId': const ValidationState.unknown(),
    'encoderCanBus': const ValidationState.valid(),
    'absoluteEncoderInverted': const ValidationState.valid(),
  };
}

class ModuleConfig {
  String locationFront = '0';
  String locationLeft = '0';
  String absoluteEncoderOffset = '0';
  String? driveType;
  String driveId = '0';
  String driveCanBus = '';
  bool invertedDrive = false;
  String? angleType;
  String angleId = '0';
  String angleCanBus = '';
  bool invertedAngle = false;
  String? encoderType;
  String encoderId = '0';
  String encoderCanBus = '';
  bool absoluteEncoderInverted = false;

  Map<String, dynamic> toJson() {
    return {
      'locationFront': locationFront,
      'locationLeft': locationLeft,
      'absoluteEncoderOffset': absoluteEncoderOffset,
      'driveType': driveType,
      'driveId': driveId,
      'driveCanBus': driveCanBus,
      'invertedDrive': invertedDrive,
      'angleType': angleType,
      'angleId': angleId,
      'angleCanBus': angleCanBus,
      'invertedAngle': invertedAngle,
      'encoderType': encoderType,
      'encoderId': encoderId,
      'encoderCanBus': encoderCanBus,
      'absoluteEncoderInverted': absoluteEncoderInverted,
    };
  }
}
