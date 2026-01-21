import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/configPages/controller_properties.dart';
import 'package:yagsl_app/configPages/module_config.dart';
import 'package:yagsl_app/configPages/physical_properties.dart';
import 'package:yagsl_app/configPages/pidf_properties.dart';
import 'package:yagsl_app/configPages/swervedrive.dart';
import 'package:yagsl_app/logs/robot_logs_page.dart';
import 'package:yagsl_app/persistent_bottom_bar_scaffold.dart';
import 'package:yagsl_app/robot_tests/absolute_encoder_offsets_page.dart';
import 'package:yagsl_app/robot_tests/drivebase_tests_menu_page.dart';
import 'package:yagsl_app/services/connection_status.dart';
import 'package:yagsl_app/services/log_store.dart';
import 'package:yagsl_app/services/robot_ip.dart';
import 'package:yagsl_app/services/robot_connection_manager.dart';
import 'package:yagsl_app/services/robot_ssh.dart';
import 'package:yagsl_app/services/tuner_project_manager.dart';
import 'package:yagsl_app/ui/config_widgets.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tab1navigatorKey = GlobalKey<NavigatorState>();
  final _tab2navigatorKey = GlobalKey<NavigatorState>();
  final _tab3navigatorKey = GlobalKey<NavigatorState>();
  bool _checkedForProject = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProjectOnLaunch();
    });
  }

  Future<void> _ensureProjectOnLaunch() async {
    if (_checkedForProject || !mounted) {
      return;
    }
    _checkedForProject = true;
    final manager = TunerProjectManager();
    final check = await manager.checkForUpdate();
    if (!mounted) {
      return;
    }

    if (check.status == TunerProjectStatus.offline && !check.hasLocal) {
      await _forceDownloadWithRetry(manager);
      return;
    }

    if (check.status == TunerProjectStatus.missing) {
      await _forceDownloadWithRetry(manager);
      return;
    }

    if (check.status == TunerProjectStatus.updateAvailable) {
      final shouldUpdate = await _promptForUpdate();
      if (shouldUpdate && mounted) {
        await _downloadWithErrorHandling(
          manager,
          required: false,
          showPrompt: false,
        );
      }
    }
  }

  Future<void> _forceDownloadWithRetry(TunerProjectManager manager) async {
    while (mounted) {
      final check = await manager.checkForUpdate();
      if (!mounted) {
        return;
      }
      if (check.status == TunerProjectStatus.offline && !check.hasLocal) {
        await _showBlockingDialog(
          title: 'Robot project required',
          message: 'Connect to the internet to download the robot project.',
          confirmLabel: 'Retry',
        );
        continue;
      }
      await _downloadWithErrorHandling(
        manager,
        required: true,
        showPrompt: true,
      );
      return;
    }
  }

  Future<void> _downloadWithErrorHandling(
    TunerProjectManager manager, {
    required bool required,
    required bool showPrompt,
  }) async {
    try {
      if (showPrompt) {
        await _showBlockingDialog(
          title: 'Download robot project',
          message: required
              ? 'A robot project is required to continue.'
              : 'A newer robot project is available.',
          confirmLabel: 'Download',
        );
      }
      await manager.ensureLatestProject();
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showBlockingDialog(
        title: 'Download failed',
        message: 'Unable to download the robot project. Try again.',
        confirmLabel: 'Retry',
      );
      if (required) {
        await _downloadWithErrorHandling(
          manager,
          required: required,
          showPrompt: showPrompt,
        );
      }
    }
  }

  Future<bool> _promptForUpdate() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update available'),
          content: const Text(
            'A new robot project is available. Download now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _showBlockingDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<DataController>();
    final configComplete = dataController.isConfigComplete();
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: TabPage1(),
          icon: Icons.settings,
          title: 'Config',
          navigatorkey: _tab1navigatorKey,
        ),
        PersistentTabItem(
          tab: const TabPage2(),
          icon: Icons.science,
          title: 'Robot Tests',
          navigatorkey: _tab2navigatorKey,
          enabled: configComplete,
          disabledMessage:
              'Complete and validate all config sections to unlock Robot Tests.',
        ),
        PersistentTabItem(
          tab: const TabPage3(),
          icon: Icons.description,
          title: 'Logs',
          navigatorkey: _tab3navigatorKey,
        ),
      ],
    );
  }
}

class TabPage1 extends StatefulWidget {
  const TabPage1({Key? key}) : super(key: key);

  @override
  State<TabPage1> createState() => _TabPage1State();
}

class _TabPage1State extends State<TabPage1> {
  final TextEditingController _teamNumberController = TextEditingController();
  final FocusNode _teamNumberFocus = FocusNode();

  ValidationState _validateTeamNumber(String value) {
    if (value.isEmpty) {
      return const ValidationState.invalid('Enter a team number.');
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return const ValidationState.invalid('Team number must be a number.');
    }
    if (parsed < 0 || parsed > 99999) {
      return const ValidationState.invalid('Team number must be 0 to 99999.');
    }
    return const ValidationState.valid();
  }

  @override
  void initState() {
    super.initState();
    final dataController = context.read<DataController>();
    _teamNumberController.text = dataController.teamNumber.toString();
  }

  @override
  void dispose() {
    _teamNumberController.dispose();
    _teamNumberFocus.dispose();
    super.dispose();
  }

  void _syncTeamNumberField(DataController dataController) {
    if (_teamNumberFocus.hasFocus) {
      return;
    }
    final desiredText = dataController.teamNumber.toString();
    if (_teamNumberController.text == desiredText) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _teamNumberFocus.hasFocus) {
        return;
      }
      _teamNumberController.text = desiredText;
      _teamNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _teamNumberController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    _syncTeamNumberField(dataController);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Config'),
        actions: const [SettingsAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          ValidatedTextField(
            label: 'Team Number',
            hintText: '1-99999',
            state: dataController.validationFor('main', 'teamNumber'),
            controller: _teamNumberController,
            focusNode: _teamNumberFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              dataController.updateValidation(
                'main',
                'teamNumber',
                _validateTeamNumber(value),
              );
              final parsed = int.tryParse(value);
              if (parsed != null) {
                dataController.setTeamNumber(parsed);
              } else {
                dataController.setTeamNumber(0);
              }
            },
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Core Config',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Swerve Drive',
            isComplete: dataController.isMenuComplete('swervedrive'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SwerveDriveConfigPage()));
            },
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Module Properties',
            isComplete: dataController.isMenuComplete('physical'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PhysicalPropertiesPage()));
            },
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Modules',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Front Left Module',
            isComplete: dataController.isMenuComplete('frontleft'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ModuleConfigPage(
                        moduleKey: 'frontleft',
                        title: 'Front Left Module',
                      )));
            },
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Front Right Module',
            isComplete: dataController.isMenuComplete('frontright'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ModuleConfigPage(
                        moduleKey: 'frontright',
                        title: 'Front Right Module',
                      )));
            },
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Back Left Module',
            isComplete: dataController.isMenuComplete('backleft'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ModuleConfigPage(
                        moduleKey: 'backleft',
                        title: 'Back Left Module',
                      )));
            },
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Back Right Module',
            isComplete: dataController.isMenuComplete('backright'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ModuleConfigPage(
                        moduleKey: 'backright',
                        title: 'Back Right Module',
                      )));
            },
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Tuning',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Heading Tuning',
            isComplete: dataController.isMenuComplete('controller'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ControllerPropertiesPage()));
            },
          ),
          const SizedBox(height: 8.0),
          ConfigMenuButton(
            label: 'Module PIDF',
            isComplete: dataController.isMenuComplete('pidf'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PidfPropertiesPage()));
            },
          ),
        ],
      ),
    );
  }
}

class TabPage2 extends StatefulWidget {
  const TabPage2({super.key});

  @override
  State<TabPage2> createState() => _TabPage2State();
}

class TabPage3 extends StatelessWidget {
  const TabPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final logStore = context.watch<LogStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline),
            onPressed: logStore.lines.isEmpty ? null : logStore.clear,
          ),
        ],
      ),
      body: logStore.lines.isEmpty
          ? const Center(child: Text('No logs yet.'))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(
                logStore.lines.join('\n'),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const RobotLogsPage(),
            ));
          },
          icon: const Icon(Icons.terminal),
          label: const Text('Robot logs'),
          style: ElevatedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(double.infinity, 50),
            shape: const BeveledRectangleBorder(),
          ),
        ),
      ),
    );
  }
}

class _TabPage2State extends State<TabPage2> {
  String? _testNumberLabel;
  bool _testNumberSubscribed = false;
  StreamSubscription<dynamic>? _testNumberSub;
  Process? _simProcess;
  bool _sshConnected = false;

  Future<void> _runGradleTask({
    required String task,
    int? teamNumber,
    bool waitForExit = true,
  }) async {
    try {
      // Step 1: Use the existing project folder
      final projectRoot =
          await TunerProjectManager().useLocalProject(teamNumber: teamNumber);
      final logStore = context.read<LogStore>();

      // Step 4: Make gradlew executable (if on a non-Windows platform)
      if (!Platform.isWindows) {
        Process.runSync(
          'chmod',
          ['+x', '$projectRoot/gradlew'],
        );
      }

      // Step 5: Run the Gradle wrapper
      final gradleWrapper = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
      if (waitForExit) {
        final result = await Process.run(
          '$projectRoot/$gradleWrapper',
          [task],
          workingDirectory: projectRoot,
          runInShell: true,
        );

        // Output results
        logStore.append('Gradle task "$task" exited ${result.exitCode}');
        if (result.stdout.toString().trim().isNotEmpty) {
          logStore.appendLines(result.stdout.toString().split('\n'));
        }
        if (result.stderr.toString().trim().isNotEmpty) {
          logStore.appendLines(result.stderr.toString().split('\n'));
        }
      } else {
        _simProcess = await Process.start(
          '$projectRoot/$gradleWrapper',
          [task],
          workingDirectory: projectRoot,
          runInShell: true,
        );
        _simProcess?.stdout
            .transform(SystemEncoding().decoder)
            .listen(logStore.append);
        _simProcess?.stderr
            .transform(SystemEncoding().decoder)
            .listen(logStore.append);
        _simProcess?.exitCode.then((code) {
          logStore.append('Sim process exited with code $code');
          _simProcess = null;
        });
      }
    } catch (e) {
      context.read<LogStore>().append('Error running Gradle: $e');
    }
  }

  Future<void> _startSimulationIfNeeded(int teamNumber) async {
    if (teamNumber != 0 || _simProcess != null) {
      return;
    }
    final projectRoot =
        await TunerProjectManager().useLocalProject(teamNumber: teamNumber);
    await _writeDeployConfigs(projectRoot);
    await _runGradleTask(
      task: 'simulateJava',
      teamNumber: teamNumber,
      waitForExit: false,
    );
  }

  Future<void> _restartSimulationWithDeploy() async {
    final simProcess = _simProcess;
    if (simProcess != null) {
      simProcess.kill();
      await simProcess.exitCode;
      _simProcess = null;
    }
    final projectRoot =
        await TunerProjectManager().useLocalProject(teamNumber: 0);
    await _writeDeployConfigs(projectRoot);
    await _runGradleTask(
      task: 'simulateJava',
      teamNumber: 0,
      waitForExit: false,
    );
  }

  Future<void> _writeDeployConfigs(String projectRoot) async {
    await context.read<DataController>().writeSwerveDeployFiles(projectRoot);
  }

  Future<bool> _waitForNt4Connection(
    RobotConnectionManager connectionManager, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (connectionManager.nt4.status == ConnectionStatus.connected) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return connectionManager.nt4.status == ConnectionStatus.connected;
  }

  Future<void> _connectWithSimulationFallback(
    RobotConnectionManager connectionManager,
  ) async {
    const host = 'localhost';
    await connectionManager.nt4.connect(server: host);
    final connected = await _waitForNt4Connection(connectionManager);
    if (!connected) {
      await _startSimulationIfNeeded(0);
      await connectionManager.nt4.connect(server: host);
      await _waitForNt4Connection(
        connectionManager,
        timeout: const Duration(seconds: 5),
      );
    }
  }

  Future<bool> _prepareDrivebaseTests(
    RobotConnectionManager connectionManager,
  ) async {
    final teamNumber = context.read<DataController>().teamNumber;
    if (teamNumber != 0) {
      final host = await resolveRobotHost(teamNumber);
      await connectionManager.nt4.connect(server: host);
      return _waitForNt4Connection(connectionManager);
    }
    await _restartSimulationWithDeploy();
    await connectionManager.nt4.connect(server: 'localhost');
    return _waitForNt4Connection(
      connectionManager,
      timeout: const Duration(seconds: 6),
    );
  }

  @override
  void dispose() {
    _testNumberSub?.cancel();
    _simProcess?.kill();
    super.dispose();
  }

  Future<void> _runTest(
    RobotConnectionManager connectionManager,
    ConnectionStatus nt4Status,
  ) async {
    if (nt4Status != ConnectionStatus.connected) {
      throw StateError('NetworkTables is not connected.');
    }
    if (!_testNumberSubscribed) {
      _testNumberSubscribed = true;
      _testNumberSub = connectionManager.nt4
          .subscribe<Object?>(
            '/SmartDashboard/testNumber',
            decoder: (value) => value,
          )
          .listen((value) {
        setState(() {
          _testNumberLabel = value?.toString();
        });
      });
    }

    await connectionManager.nt4
        .publishBoolWhenAnnounced('/SmartDashboard/test/running', true);
  }

  @override
  Widget build(BuildContext context) {
    final dataController = Provider.of<DataController>(context);
    final connectionManager = context.read<RobotConnectionManager>();
    final nt4Connected =
        dataController.nt4Status == ConnectionStatus.connected;
    final testsEnabled = dataController.teamNumber == 0
        ? nt4Connected
        : nt4Connected && _sshConnected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Tests'),
        actions: [
          _ConnectionIndicatorRow(
            nt4Status: dataController.nt4Status,
          ),
          const SettingsAction(),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        alignment: Alignment.topLeft,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Connection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final teamNumber = dataController.teamNumber;
                if (teamNumber == 0) {
                  await _connectWithSimulationFallback(connectionManager);
                } else {
                  if (mounted) {
                    setState(() {
                      _sshConnected = false;
                    });
                  }
                  await _runGradleTask(
                    task: 'deploy',
                    teamNumber: teamNumber,
                  );
                  final host = await resolveRobotHost(teamNumber);
                  await connectionManager.nt4.connect(server: host);
                  try {
                    final result = await const RobotSsh()
                        .run(teamNumber, 'true');
                    if (mounted) {
                      setState(() {
                        _sshConnected = result.exitCode == 0;
                      });
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(() {
                        _sshConnected = false;
                      });
                    }
                  }
                }
              },
              icon: const Icon(Icons.wifi),
              label: Text(dataController.teamNumber != 0
                  ? 'Connect to robot'
                  : 'Connect to robot simulation'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: testsEnabled
                  ? () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AbsoluteEncoderOffsetsPage(
                          connectionManager: connectionManager,
                        ),
                      ));
                    }
                  : null,
              child: const Text('Absolute encoder offsets'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: testsEnabled
                  ? () async {
                final connected =
                    await _prepareDrivebaseTests(connectionManager);
                if (!mounted) {
                  return;
                }
                if (!connected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to connect to NetworkTables.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DrivebaseTestsMenuPage(
                    connectionManager: connectionManager,
                  ),
                ));
              }
                  : null,
              child: const Text('Drivebase tests'),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Post-tests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'After you have ran all the tests your module inversions and abs encoder offset should be correct, use this config on a regular YAGSL program and see if everything functions correctly.  Currently the app does not handle IMU inversion, that might have to be changed after the fact if it has an issue.  You can export the config with the button below',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: dataController.isConfigComplete()
                  ? () async {
                      final savePath =
                          await FilePicker.platform.saveFile(
                        dialogTitle: 'Export config ZIP',
                        fileName: 'yagsl_config.zip',
                        type: FileType.custom,
                        allowedExtensions: ['zip'],
                      );
                      if (savePath == null) {
                        return;
                      }
                      final files = dataController.buildSwerveConfigJson();
                      final archive = Archive();
                      files.forEach((path, contents) {
                        final bytes = utf8.encode(contents);
                        archive.addFile(
                          ArchiveFile(path, bytes.length, bytes),
                        );
                      });
                      final zipBytes = ZipEncoder().encode(archive);
                      if (zipBytes == null) {
                        throw StateError('Failed to build ZIP archive.');
                      }
                      final output = File(savePath);
                      await output.writeAsBytes(zipBytes);
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exported config ZIP.'),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.file_download),
              label: const Text('Export config ZIP'),
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

class _ConnectionIndicatorRow extends StatelessWidget {
  final ConnectionStatus nt4Status;

  const _ConnectionIndicatorRow({
    required this.nt4Status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ConnectionIndicator(
            label: 'Robot',
            tooltipLabel: 'NetworkTables',
            status: nt4Status,
          ),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final String label;
  final String tooltipLabel;
  final ConnectionStatus status;

  const _ConnectionIndicator({
    required this.label,
    required this.tooltipLabel,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Tooltip(
      message: _statusLabel(tooltipLabel, status),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ConnectionStatus status) {
  switch (status) {
    case ConnectionStatus.connected:
      return Colors.green;
    case ConnectionStatus.connecting:
      return Colors.orange;
    case ConnectionStatus.error:
      return Colors.red;
    case ConnectionStatus.disconnected:
      return Colors.grey;
  }
}

String _statusLabel(String label, ConnectionStatus status) {
  switch (status) {
    case ConnectionStatus.connected:
      return 'Connected to $label';
    case ConnectionStatus.connecting:
      return 'Connecting to $label';
    case ConnectionStatus.error:
      return '$label error';
    case ConnectionStatus.disconnected:
      return 'Disconnected from $label';
  }
}
