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

class DriveTestPage extends StatefulWidget {
  final RobotConnectionManager connectionManager;
  final ValueNotifier<bool> configChanged;

  const DriveTestPage({
    super.key,
    required this.connectionManager,
    required this.configChanged,
  });

  @override
  State<DriveTestPage> createState() => _DriveTestPageState();
}

class _DriveTestPageState extends State<DriveTestPage> {
  static const _fmsKey = '/FMSInfo/FMSControlData';
  static const _driveKey = '/SmartDashboard/driveForward/running';

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

  Future<void> _runDriveTest() async {
    var rerun = false;
    do {
      final success = await _runWithBlockingUi(() async {
        await widget.connectionManager.nt4
            .publishBoolWhenAnnounced(_driveKey, true);
        await widget.connectionManager.nt4
            .subscribe<Object?>(_driveKey, decoder: (value) => value)
            .where((value) => value == false)
            .first
            .timeout(const Duration(seconds: 15));
      });
      if (!success || !mounted) {
        return;
      }
      rerun = await _showDriveResults();
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

  Future<bool> _showDriveResults() async {
    final dataController = context.read<DataController>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Drive test results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Each module should have driven forward, if it went in the opposite direction click the appropriate invert button below and run the test again. If it was another issue, like it not driving forward or backward, verify previous config options where correct, both on the hardware side and the ABS encoder offset.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _invertButton(
                        label: 'Front Left',
                        inverted: dataController.modules['frontleft']
                                ?.invertedDrive ??
                            false,
                        onPressed: () {
                          _toggleInverted('frontleft', isAngle: false);
                          setState(() {});
                        },
                      ),
                      _invertButton(
                        label: 'Front Right',
                        inverted: dataController.modules['frontright']
                                ?.invertedDrive ??
                            false,
                        onPressed: () {
                          _toggleInverted('frontright', isAngle: false);
                          setState(() {});
                        },
                      ),
                      _invertButton(
                        label: 'Back Left',
                        inverted: dataController.modules['backleft']
                                ?.invertedDrive ??
                            false,
                        onPressed: () {
                          _toggleInverted('backleft', isAngle: false);
                          setState(() {});
                        },
                      ),
                      _invertButton(
                        label: 'Back Right',
                        inverted: dataController.modules['backright']
                                ?.invertedDrive ??
                            false,
                        onPressed: () {
                          _toggleInverted('backright', isAngle: false);
                          setState(() {});
                        },
                      ),
                    ],
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
            ],
          );
        });
      },
    );
    return result ?? false;
  }

  Widget _invertButton({
    required String label,
    required bool inverted,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text('$label: ${inverted ? 'Inverted' : 'Normal'}'),
    );
  }

  void _toggleInverted(String key, {required bool isAngle}) {
    final dataController = context.read<DataController>();
    if (dataController.teamNumber == 0) {
      return;
    }
    final module = dataController.modules[key];
    if (module == null) {
      return;
    }
    if (isAngle) {
      module.invertedAngle = !module.invertedAngle;
      dataController.updateValidation(
        key,
        'invertedAngle',
        const ValidationState.valid(),
      );
    } else {
      module.invertedDrive = !module.invertedDrive;
      dataController.updateValidation(
        key,
        'invertedDrive',
        const ValidationState.valid(),
      );
    }
    widget.configChanged.value = true;
    if (mounted) {
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    final nt4Status = context.watch<DataController>().nt4Status;
    final connected = nt4Status == ConnectionStatus.connected;
    final canRun = connected && _teleopEnabled && !_runningTest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Test'),
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
              onPressed: canRun ? _runDriveTest : null,
              icon: const Icon(Icons.directions_car),
              label: const Text('Run drive test'),
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
