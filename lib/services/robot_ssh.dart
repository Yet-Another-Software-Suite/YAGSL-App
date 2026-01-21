import 'dart:io';

import 'package:yagsl_app/services/robot_ip.dart';

class RobotSsh {
  final String user;
  final List<String> defaultArgs;

  const RobotSsh({
    this.user = 'admin',
    this.defaultArgs = const [
      '-o',
      'BatchMode=yes',
      '-o',
      'ConnectTimeout=3',
      '-o',
      'StrictHostKeyChecking=no',
      '-o',
      'UserKnownHostsFile=/dev/null',
    ],
  });

  Future<ProcessResult> run(
    int teamNumber,
    String command, {
    List<String> sshArgs = const [],
  }) async {
    final host = await resolveRobotHost(teamNumber);
    if (host.isEmpty) {
      throw StateError('Unable to resolve robot host.');
    }
    final args = [
      ...defaultArgs,
      ...sshArgs,
      '$user@$host',
      command,
    ];
    return Process.run('ssh', args);
  }

  Future<ProcessResult> upload(
    int teamNumber, {
    required String localPath,
    required String remotePath,
    List<String> scpArgs = const [],
  }) async {
    final host = await resolveRobotHost(teamNumber);
    if (host.isEmpty) {
      throw StateError('Unable to resolve robot host.');
    }
    final args = [
      ...defaultArgs,
      ...scpArgs,
      localPath,
      '$user@$host:$remotePath',
    ];
    return Process.run('scp', args);
  }

  Future<ProcessResult> remove(
    int teamNumber,
    String remotePath, {
    List<String> sshArgs = const [],
  }) async {
    return run(
      teamNumber,
      'rm -rf "$remotePath"',
      sshArgs: sshArgs,
    );
  }
}
