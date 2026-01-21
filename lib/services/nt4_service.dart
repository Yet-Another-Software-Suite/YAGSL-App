import 'dart:developer';

import 'package:nt4/nt4.dart';

import 'connection_status.dart';

class Nt4Service {
  final StatusCallback? onStatus;

  ConnectionStatus status = ConnectionStatus.disconnected;
  String? lastError;
  String? server;
  int? port;
  NT4Client? _client;
  final Map<String, NT4Topic> _publishedTopics = {};

  Nt4Service({this.onStatus});

  Future<void> connect({required String server, int port = 5810}) async {
    this.server = server;
    this.port = port;
    _setStatus(ConnectionStatus.connecting);
    log('Connecting to NetworkTables at $server:$port', name: 'nt4');
    if (_client == null) {
      _client = NT4Client(
        serverBaseAddress: server,
        onConnect: () {
          log('NetworkTables connected', name: 'nt4');
          _setStatus(ConnectionStatus.connected);
        },
        onDisconnect: () {
          log('NetworkTables disconnected', name: 'nt4');
          _setStatus(ConnectionStatus.disconnected);
        },
      );
    } else {
      log('NetworkTables switching server to $server:$port', name: 'nt4');
      _client!.setServerBaseAddress(server);
    }
  }

  Future<void> disconnect() async {
    _fail('Nt4Service.disconnect is not implemented yet.');
  }

  Future<void> publishBool(String topic, bool value) async {
    if (status != ConnectionStatus.connected) {
      return Future.error(
        StateError('Nt4Service.publishBool called while disconnected.'),
      );
    }
    final client = _client;
    if (client == null) {
      return Future.error(
        StateError('Nt4Service.publishBool called before connect.'),
      );
    }
    final published = _publishedTopics[topic] ??
        client.publishNewTopic(topic, NT4TypeStr.typeBool);
    _publishedTopics[topic] = published;
    client.addSample(published, value);
    log('Published $topic = $value', name: 'nt4');
  }

  Future<void> publishTransientBool(String topic, bool value) async {
    if (status != ConnectionStatus.connected) {
      return Future.error(
        StateError('Nt4Service.publishTransientBool called while disconnected.'),
      );
    }
    final client = _client;
    if (client == null) {
      return Future.error(
        StateError('Nt4Service.publishTransientBool called before connect.'),
      );
    }
    final published = client.publishNewTopic(topic, NT4TypeStr.typeBool);
    client.addSample(published, value);
    client.unpublishTopic(published);
    log('Published transient $topic = $value', name: 'nt4');
  }

  Future<void> publishBoolOnExistingTopic(String topic, bool value) async {
    if (status != ConnectionStatus.connected) {
      return Future.error(
        StateError('Nt4Service.publishBoolOnExistingTopic while disconnected.'),
      );
    }
    final client = _client;
    if (client == null) {
      return Future.error(
        StateError('Nt4Service.publishBoolOnExistingTopic before connect.'),
      );
    }
    final existing = client.getTopicFromName(topic);
    if (existing == null) {
      return Future.error(
        StateError('Nt4Service.publishBoolOnExistingTopic topic missing.'),
      );
    }
    if (!_publishedTopics.containsKey(topic)) {
      client.publishTopic(existing);
      _publishedTopics[topic] = existing;
    }
    client.addSample(existing, value);
    log('Published existing $topic = $value', name: 'nt4');
  }

  Future<void> publishBoolWhenAnnounced(
    String topic,
    bool value, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (status != ConnectionStatus.connected) {
      return Future.error(
        StateError('Nt4Service.publishBoolWhenAnnounced while disconnected.'),
      );
    }
    final client = _client;
    if (client == null) {
      return Future.error(
        StateError('Nt4Service.publishBoolWhenAnnounced before connect.'),
      );
    }

    final subscription = client.subscribePeriodic(topic);
    final deadline = DateTime.now().add(timeout);
    NT4Topic? existing;

    while (DateTime.now().isBefore(deadline)) {
      existing = client.getTopicFromName(topic);
      if (existing != null) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    client.unSubscribe(subscription);

    if (existing == null) {
      return Future.error(
        StateError('Nt4Service.publishBoolWhenAnnounced topic missing.'),
      );
    }

    if (!_publishedTopics.containsKey(topic)) {
      client.publishTopic(existing);
      _publishedTopics[topic] = existing;
    }
    client.addSample(existing, value);
    log('Published existing $topic = $value', name: 'nt4');
  }

  Stream<T> subscribe<T>(
    String topic, {
    required T Function(dynamic value) decoder,
  }) {
    if (status != ConnectionStatus.connected) {
      return Stream<T>.error(
        StateError('Nt4Service.subscribe called while disconnected.'),
      );
    }
    final client = _client;
    if (client == null) {
      return Stream<T>.error(
        StateError('Nt4Service.subscribe called before connect.'),
      );
    }
    final subscription = client.subscribePeriodic(topic);
    log('Subscribed to $topic', name: 'nt4');
    return subscription.stream().map((value) {
      log('Received $topic = $value', name: 'nt4');
      return decoder(value);
    });
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
