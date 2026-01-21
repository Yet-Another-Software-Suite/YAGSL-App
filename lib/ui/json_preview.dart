import 'dart:convert';

import 'package:flutter/material.dart';

class JsonPreviewPanel extends StatelessWidget {
  final String title;
  final Map<String, dynamic> json;

  const JsonPreviewPanel({
    Key? key,
    required this.title,
    required this.json,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final encoder = const JsonEncoder.withIndent('  ');
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  encoder.convert(json),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
