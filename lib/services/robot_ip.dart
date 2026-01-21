import 'dart:io';

const String robotUsbIp = '172.22.11.2';

String robotIpForTeam(int teamNumber) {
  if (teamNumber <= 0) {
    return '';
  }
  final teamPrefix = teamNumber ~/ 100;
  final teamSuffix = teamNumber % 100;
  return '10.$teamPrefix.$teamSuffix.2';
}

String robotMdnsForTeam(int teamNumber) {
  if (teamNumber <= 0) {
    return '';
  }
  return 'roboRIO-$teamNumber-FRC.local';
}

Future<bool> pingHost(String host) async {
  if (host.isEmpty) {
    return false;
  }
  final args = Platform.isWindows
      ? ['-n', '1', host]
      : ['-c', '1', host];
  final result = await Process.run('ping', args);
  return result.exitCode == 0;
}

Future<String> resolveRobotHost(int teamNumber) async {
  if (await pingHost(robotUsbIp)) {
    return robotUsbIp;
  }
  final ip = robotIpForTeam(teamNumber);
  if (await pingHost(ip)) {
    return ip;
  }
  return robotMdnsForTeam(teamNumber);
}
