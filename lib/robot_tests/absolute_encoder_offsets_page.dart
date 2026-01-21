import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/DataController.dart';
import 'package:yagsl_app/services/connection_status.dart';
import 'package:yagsl_app/services/robot_connection_manager.dart';
import 'package:yagsl_app/ui/settings_action.dart';
import 'package:yagsl_app/ui/validation.dart';

class AbsoluteEncoderOffsetsPage extends StatefulWidget {
  final RobotConnectionManager connectionManager;

  const AbsoluteEncoderOffsetsPage({
    super.key,
    required this.connectionManager,
  });

  @override
  State<AbsoluteEncoderOffsetsPage> createState() =>
      _AbsoluteEncoderOffsetsPageState();
}

class _AbsoluteEncoderOffsetsPageState
    extends State<AbsoluteEncoderOffsetsPage> {
  bool _isLoading = false;

  Future<double> _readOffset(String moduleKey) async {
    final topic =
        '/SmartDashboard/swerve/modules/$moduleKey/Raw Absolute Encoder';
    Object? value;
    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        value = await widget.connectionManager.nt4
            .subscribe<Object?>(topic, decoder: (value) => value)
            .where((sample) => sample != null)
            .first
            .timeout(const Duration(seconds: 2));
        break;
      } on TimeoutException {
        if (attempt == 2) {
          rethrow;
        }
      }
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      throw StateError('Invalid encoder value for $moduleKey: $value');
    }
    return parsed;
  }

  ValidationState _validateOffset(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return const ValidationState.invalid('Offset must be a number.');
    }
    return const ValidationState.valid();
  }

  Future<void> _applyOffsets() async {
    final dataController = context.read<DataController>();
    setState(() {
      _isLoading = true;
    });
    try {
      final moduleKeys = [
        'frontleft',
        'frontright',
        'backleft',
        'backright',
      ];
      final offsets = <String, double>{};
      for (final key in moduleKeys) {
        offsets[key] = await _readOffset(key);
      }

      offsets.forEach((key, value) {
        final module = dataController.modules[key];
        if (module == null) {
          return;
        }
        module.absoluteEncoderOffset = value.toString();
        dataController.updateValidation(
          key,
          'absoluteEncoderOffset',
          _validateOffset(module.absoluteEncoderOffset),
        );
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absolute encoder offsets updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read offsets: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nt4Status = context.watch<DataController>().nt4Status;
    final teamNumber = context.watch<DataController>().teamNumber;
    final connected = nt4Status == ConnectionStatus.connected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absolute Encoder Offsets'),
        actions: const [SettingsAction()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teamNumber == 0)
              const Text(
                'Simulated ABS encoder offsets will always end up as 0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (teamNumber == 0) const SizedBox(height: 12.0),
            const Text(
              'To correctly get the absoluteEncoderOffset your swerve modules must be facing this way while reading the values.',
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(
                  'assets/robot_tests/absolute_encoder_offsets.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Add image at assets/robot_tests/absolute_encoder_offsets.png',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: connected && !_isLoading ? _applyOffsets : null,
              icon: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Get absolute encoder offsets'),
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
