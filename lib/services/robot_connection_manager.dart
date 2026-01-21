import 'connection_status.dart';
import 'nt4_service.dart';

class RobotConnectionManager {
  final Nt4Service nt4;

  ConnectionStatus status = ConnectionStatus.disconnected;
  String? lastError;
  final StatusCallback? onStatus;

  RobotConnectionManager({
    Nt4Service? nt4Service,
    StatusCallback? nt4StatusUpdater,
    this.onStatus,
  }) : nt4 = nt4Service ?? Nt4Service(onStatus: nt4StatusUpdater);

  Future<void> connectAll({
    required String host,
    int ntPort = 5810,
  }) async {
    _setStatus(ConnectionStatus.connecting);
    _fail('RobotConnectionManager.connectAll not ready.');
  }

  Future<void> disconnectAll() async {
    _setStatus(ConnectionStatus.disconnected);
    _fail('RobotConnectionManager.disconnectAll not ready.');
  }

  void _setStatus(ConnectionStatus next) {
    status = next;
    onStatus?.call(next);
  }

  Never _fail(String message) {
    lastError = message;
    _setStatus(ConnectionStatus.error);
    throw UnimplementedError(message);
  }
}
