import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/services/robot_ssh.dart';

class RobotLogsPage extends StatefulWidget {
  const RobotLogsPage({super.key});

  @override
  State<RobotLogsPage> createState() => _RobotLogsPageState();
}

class _RobotLogsPageState extends State<RobotLogsPage> {
  Process? _process;
  final List<String> _lines = [];
  bool _starting = false;
  String? _error;

  @override
  void dispose() {
    _stopTail();
    super.dispose();
  }

  Future<void> _startTail() async {
    if (_starting || _process != null) {
      return;
    }
    final teamNumber = context.read<DataController>().teamNumber;
    if (teamNumber == 0) {
      setState(() {
        _error = 'Robot logs are only available in robot mode.';
      });
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final ssh = const RobotSsh(user: 'lvuser');
      final process = await ssh.start(
        teamNumber,
        'tail -f /home/lvuser/FRC_UserProgram.log',
      );
      _process = process;
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_appendLine);
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_appendLine);
      process.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _error = 'Robot log stream exited (code $code).';
            _process = null;
          });
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start robot logs: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
    }
  }

  void _stopTail() {
    _process?.kill();
    _process = null;
  }

  void _appendLine(String line) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lines.add(line);
      if (_lines.length > 2000) {
        _lines.removeRange(0, _lines.length - 2000);
      }
    });
  }

  void _clear() {
    setState(() {
      _lines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _process != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline),
            onPressed: _lines.isEmpty ? null : _clear,
          ),
          IconButton(
            tooltip: isRunning ? 'Stop' : 'Start',
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _starting ? null : (isRunning ? _stopTail : _startTail),
          ),
        ],
      ),
      body: _lines.isEmpty
          ? Center(
              child: Text(
                _error ?? 'No robot log output yet.',
                textAlign: TextAlign.center,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(_lines.join('\n')),
            ),
    );
  }
}
