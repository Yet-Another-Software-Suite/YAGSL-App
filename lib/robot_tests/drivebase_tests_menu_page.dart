import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/robot_tests/drive_test_page.dart';
import 'package:yagsl_app/robot_tests/steer_test_page.dart';
import 'package:yagsl_app/services/connection_status.dart';
import 'package:yagsl_app/services/robot_connection_manager.dart';
import 'package:yagsl_app/services/tuner_project_manager.dart';
import 'package:yagsl_app/ui/settings_action.dart';

class DrivebaseTestsMenuPage extends StatefulWidget {
  final RobotConnectionManager connectionManager;

  const DrivebaseTestsMenuPage({
    super.key,
    required this.connectionManager,
  });

  @override
  State<DrivebaseTestsMenuPage> createState() => _DrivebaseTestsMenuPageState();
}

class _DrivebaseTestsMenuPageState extends State<DrivebaseTestsMenuPage> {
  final ValueNotifier<bool> _configChanged = ValueNotifier<bool>(false);

  Future<void> _redeployIfNeeded() async {
    if (!_configChanged.value) {
      return;
    }
    final dataController = context.read<DataController>();
    if (dataController.teamNumber != 0) {
      _configChanged.value = false;
      return;
    }
    final projectRoot = await TunerProjectManager()
        .useLocalProject(teamNumber: dataController.teamNumber);
    await dataController.writeSwerveDeployFiles(projectRoot);
    _configChanged.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final nt4Status = context.watch<DataController>().nt4Status;
    final connected = nt4Status == ConnectionStatus.connected;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _redeployIfNeeded();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drivebase Tests'),
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: connected
                    ? () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SteerTestPage(
                            connectionManager: widget.connectionManager,
                            configChanged: _configChanged,
                          ),
                        ));
                      }
                    : null,
                icon: const Icon(Icons.sync),
                label: const Text('Steer test'),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(double.infinity, 50),
                  shape: const BeveledRectangleBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: connected
                    ? () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => DriveTestPage(
                            connectionManager: widget.connectionManager,
                            configChanged: _configChanged,
                          ),
                        ));
                      }
                    : null,
                icon: const Icon(Icons.directions_car),
                label: const Text('Drive test'),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(double.infinity, 50),
                  shape: const BeveledRectangleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
