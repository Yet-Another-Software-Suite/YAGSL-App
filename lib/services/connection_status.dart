enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

typedef StatusCallback = void Function(ConnectionStatus status);
