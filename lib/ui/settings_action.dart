import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yagsl_app/settings_controller.dart';
import 'package:yagsl_app/DataController.dart';

class SettingsAction extends StatelessWidget {
  const SettingsAction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (context) {
              return Consumer<SettingsController>(
                builder: (context, settings, _) {
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12.0),
                    SwitchListTile(
                      value: settings.isDarkMode,
                      title: const Text('Dark mode'),
                      onChanged: settings.setDarkMode,
                      subtitle: settings.themeMode == ThemeMode.system
                          ? const Text('Following system theme')
                          : null,
                    ),
                    const SizedBox(height: 8.0),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<DataController>().resetRobotConfigs();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset robot configs'),
                    ),
                    const SizedBox(height: 8.0),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final dataController =
                            context.read<DataController>();
                        if (!dataController.isConfigComplete()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Complete and validate configs before export.',
                              ),
                            ),
                          );
                          return;
                        }
                        final savePath =
                            await FilePicker.platform.saveFile(
                          dialogTitle: 'Export config ZIP',
                          fileName: 'yagsl_config.zip',
                          type: FileType.custom,
                          allowedExtensions: ['zip'],
                        );
                        if (savePath == null) {
                          return;
                        }
                        final files = dataController.buildSwerveConfigJson();
                        final archive = Archive();
                        files.forEach((path, contents) {
                          final bytes = utf8.encode(contents);
                          archive.addFile(
                            ArchiveFile(path, bytes.length, bytes),
                          );
                        });
                        final zipBytes = ZipEncoder().encode(archive);
                        if (zipBytes == null) {
                          throw StateError('Failed to build ZIP archive.');
                        }
                        final output = File(savePath);
                        await output.writeAsBytes(zipBytes);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exported config ZIP.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export config ZIP'),
                    ),
                    const SizedBox(height: 8.0),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final rootPath =
                            await FilePicker.platform.getDirectoryPath(
                          dialogTitle: 'Select swerve config folder',
                        );
                        if (rootPath == null) {
                          return;
                        }
                        try {
                          await context
                              .read<DataController>()
                              .importFromSwerveDirectory(rootPath);
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Import failed: $error'),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Imported config files.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Import config folder'),
                    ),
                  ],
                );
              },
            );
            },
          );
        },
      ),
    );
  }
}
