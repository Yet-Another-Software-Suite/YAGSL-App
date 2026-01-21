import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/services/connection_status.dart';
import 'package:yagsl_app/services/robot_connection_manager.dart';
import 'package:yagsl_app/services/robot_ssh.dart';
import 'package:yagsl_app/services/tuner_project_manager.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class SteerTestPage extends StatefulWidget {
  final RobotConnectionManager connectionManager;
  final ValueNotifier<bool> configChanged;

  const SteerTestPage({
    super.key,
    required this.connectionManager,
    required this.configChanged,
  });

  @override
  State<SteerTestPage> createState() => _SteerTestPageState();
}

class _SteerTestPageState extends State<SteerTestPage> {
  static const _fmsKey = '/FMSInfo/FMSControlData';
  static const _moduleLabels = {
    'frontleft': 'Front Left',
    'frontright': 'Front Right',
    'backleft': 'Back Left',
    'backright': 'Back Right',
  };

  StreamSubscription<dynamic>? _fmsSub;
  bool _teleopEnabled = false;
  bool _runningTest = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _subscribeFmsStatus();
  }

  @override
  void dispose() {
    _fmsSub?.cancel();
    super.dispose();
  }

  void _subscribeFmsStatus() {
    _fmsSub?.cancel();
    _fmsSub = widget.connectionManager.nt4
        .subscribe<Object?>(_fmsKey, decoder: (value) => value)
        .listen((value) {
      final parsed = value is num ? value.toInt() : int.tryParse('$value');
      final enabled = parsed == 33;
      if (mounted) {
        setState(() {
          _teleopEnabled = enabled;
        });
      }
    });
  }

  Future<void> _runSteerTestForModule(String moduleKey) async {
    final moduleName = _moduleNameForNt(moduleKey);
    final steerKey = '/SmartDashboard/spin$moduleName/running';
    var rerun = false;
    do {
      final success = await _runWithBlockingUi(() async {
        await widget.connectionManager.nt4
            .publishBoolWhenAnnounced(steerKey, true);
        await widget.connectionManager.nt4
            .subscribe<Object?>(steerKey, decoder: (value) => value)
            .where((value) => value == false)
            .first
            .timeout(const Duration(seconds: 15));
      });
      if (!success || !mounted) {
        return;
      }
      rerun = await _showSteerResults(moduleKey);
    } while (rerun);
    await _redeployIfNeeded();
  }

  Future<bool> _runWithBlockingUi(Future<void> Function() action) async {
    if (!mounted) {
      return false;
    }
    setState(() {
      _runningTest = true;
    });
    _dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Running test...')),
            ],
          ),
        );
      },
    );
    try {
      await action();
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test failed: $error')),
      );
      return false;
    } finally {
      if (!mounted) {
        return false;
      }
      if (_dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _dialogOpen = false;
      }
      setState(() {
        _runningTest = false;
      });
    }
  }

  Future<bool> _showSteerResults(String moduleKey) async {
    final dataController = context.read<DataController>();
    final label = _moduleLabels[moduleKey] ?? moduleKey;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Steer test results: $label'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Did the module spin CCW or CW during the test?',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current steer inversion: ${dataController.modules[moduleKey]?.invertedAngle == true ? 'Inverted' : 'Normal'}',
                  ),
                  Text(
                    'Current ABS inversion: ${dataController.modules[moduleKey]?.absoluteEncoderInverted == true ? 'Inverted' : 'Normal'}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Re-run test'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _applySteerResult(moduleKey, 1);
                    if (context.mounted) {
                      Navigator.of(context).pop(false);
                    }
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to apply result: $error'),
                      ),
                    );
                  }
                },
                child: const Text('Spun CCW'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _applySteerResult(moduleKey, -1);
                    if (context.mounted) {
                      Navigator.of(context).pop(false);
                    }
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to apply result: $error'),
                      ),
                    );
                  }
                },
                child: const Text('Spun CW'),
              ),
            ],
          );
        });
      },
    );
    return result ?? false;
  }

  Future<void> _applySteerResult(String key, int sign) async {
    final dataController = context.read<DataController>();
    if (dataController.teamNumber == 0) {
      return;
    }
    final module = dataController.modules[key];
    if (module == null) {
      return;
    }
    final absDelta = await _readAbsDelta(key);
    module.invertedAngle = sign < 0;
    module.absoluteEncoderInverted = (sign * absDelta) < 0;
    dataController.updateValidation(
      key,
      'invertedAngle',
      const ValidationState.valid(),
    );
    dataController.updateValidation(
      key,
      'absoluteEncoderInverted',
      const ValidationState.valid(),
    );
    widget.configChanged.value = true;
  }

  Future<double> _readAbsDelta(String moduleKey) async {
    final moduleName = _moduleNameForNt(moduleKey);
    final topic = '/SmartDashboard/module${moduleName}AbsDelta';
    Object? value;
    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        value = await widget.connectionManager.nt4
            .subscribe<Object?>(topic, decoder: (value) => value)
            .where((sample) => sample != null)
            .first
            .timeout(const Duration(seconds: 2));
        break;
      } on TimeoutException {
        if (attempt == 2) {
          rethrow;
        }
      }
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      throw StateError('Invalid ABS delta for $moduleKey: $value');
    }
    return parsed;
  }

  Future<void> _redeployIfNeeded() async {
    if (!widget.configChanged.value) {
      return;
    }
    final dataController = context.read<DataController>();
    if (dataController.teamNumber != 0) {
      await _redeployToRobot(dataController.teamNumber);
      widget.configChanged.value = false;
      return;
    }
    final projectRoot = await TunerProjectManager()
        .useLocalProject(teamNumber: dataController.teamNumber);
    await dataController.writeSwerveDeployFiles(projectRoot);
    widget.configChanged.value = false;
  }

  Future<void> _redeployToRobot(int teamNumber) async {
    final dataController = context.read<DataController>();
    final tempDir = await Directory.systemTemp.createTemp('yagsl_deploy_');
    final swerveDir = Directory('${tempDir.path}/swerve');
    await swerveDir.create(recursive: true);
    final files = dataController.buildSwerveConfigJson();
    for (final entry in files.entries) {
      final filePath = '${tempDir.path}/${entry.key}';
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString(entry.value);
    }

    final ssh = const RobotSsh();
    await ssh.run(
      teamNumber,
      'rm -rf /home/lvuser/deploy/swerve && mkdir -p /home/lvuser/deploy/swerve',
    );
    await ssh.upload(
      teamNumber,
      localPath: swerveDir.path,
      remotePath: '/home/lvuser/deploy/',
      scpArgs: const ['-r'],
    );
    await ssh.run(
      teamNumber,
      '/usr/local/bin/frc/bin/frcKillRobot.sh -r',
    );

    await tempDir.delete(recursive: true);
  }

  String _moduleNameForNt(String moduleKey) {
    switch (moduleKey) {
      case 'frontleft':
        return 'FrontLeft';
      case 'frontright':
        return 'FrontRight';
      case 'backleft':
        return 'BackLeft';
      case 'backright':
        return 'BackRight';
    }
    return moduleKey;
  }

  @override
  Widget build(BuildContext context) {
    final nt4Status = context.watch<DataController>().nt4Status;
    final connected = nt4Status == ConnectionStatus.connected;
    final canRun = connected && _teleopEnabled && !_runningTest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steer Test'),
        actions: const [SettingsAction()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connected
                  ? 'NetworkTables connected'
                  : 'NetworkTables disconnected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: connected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _teleopEnabled
                  ? 'Robot enabled (teleop)'
                  : 'Robot must be enabled in teleop to run tests.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: canRun
                  ? () => _runSteerTestForModule('frontleft')
                  : null,
              icon: const Icon(Icons.sync),
              label: const Text('Run steer test: Front Left'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: canRun
                  ? () => _runSteerTestForModule('frontright')
                  : null,
              icon: const Icon(Icons.sync),
              label: const Text('Run steer test: Front Right'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: canRun ? () => _runSteerTestForModule('backleft') : null,
              icon: const Icon(Icons.sync),
              label: const Text('Run steer test: Back Left'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: canRun
                  ? () => _runSteerTestForModule('backright')
                  : null,
              icon: const Icon(Icons.sync),
              label: const Text('Run steer test: Back Right'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
