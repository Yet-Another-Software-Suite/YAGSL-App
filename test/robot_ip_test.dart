import 'package:flutter_test/flutter_test.dart';
import 'package:yagsl_app/services/robot_ip.dart';

void main() {
  test('robotIpForTeam builds expected ip', () {
    expect(robotIpForTeam(1), '10.0.1.2');
    expect(robotIpForTeam(12), '10.0.12.2');
    expect(robotIpForTeam(122), '10.1.22.2');
    expect(robotIpForTeam(1002), '10.10.2.2');
    expect(robotIpForTeam(1212), '10.12.12.2');
    expect(robotIpForTeam(1202), '10.12.2.2');
    expect(robotIpForTeam(1220), '10.12.20.2');
    expect(robotIpForTeam(3456), '10.34.56.2');
    expect(robotIpForTeam(10000), '10.100.0.2');
    expect(robotIpForTeam(12345), '10.123.45.2');
  });
}
