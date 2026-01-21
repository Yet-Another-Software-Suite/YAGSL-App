import 'package:flutter/material.dart';
import 'package:yagsl_app/ui/json_preview.dart';

class ConfigPageLayout extends StatelessWidget {
  final Widget form;
  final Map<String, dynamic> json;
  final String jsonTitle;

  const ConfigPageLayout({
    Key? key,
    required this.form,
    required this.json,
    required this.jsonTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final preview = JsonPreviewPanel(title: jsonTitle, json: json);
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: form),
              const SizedBox(width: 16.0),
              SizedBox(width: 360, child: preview),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: form),
            const Divider(height: 1.0),
            SizedBox(height: 260, child: preview),
          ],
        );
      },
    );
  }
}
