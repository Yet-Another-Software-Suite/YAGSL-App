import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TunerProjectManager {
  static const _zipUrl =
      'https://github.com/Yet-Another-Software-Suite/YAGSL-Tuner/archive/refs/heads/main.zip';
  static const _cacheTagKey = 'tuner_project_cache_tag';
  static const _etagKey = 'tuner_project_etag';
  static const _lastModifiedKey = 'tuner_project_last_modified';
  static const _rootFolderKey = 'tuner_project_root_folder';

  Future<TunerProjectCheck> checkForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final appSupportDir = await getApplicationSupportDirectory();
    final existingRoot = prefs.getString(_rootFolderKey);
    final existingRootPath =
        existingRoot == null ? null : '${appSupportDir.path}/$existingRoot';
    final existingRootExists =
        existingRootPath != null && Directory(existingRootPath).existsSync();
    if (!existingRootExists) {
      return _checkRemoteStatus(hasLocal: false, etag: null, lastModified: null);
    }
    final etag = prefs.getString(_etagKey) ?? prefs.getString(_cacheTagKey);
    final lastModified = prefs.getString(_lastModifiedKey);
    return _checkRemoteStatus(
      hasLocal: true,
      etag: etag,
      lastModified: lastModified,
    );
  }

  Future<String> ensureLatestProject({int? teamNumber}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appSupportDir = await getApplicationSupportDirectory();
      final existingRoot = prefs.getString(_rootFolderKey);
      final existingRootPath = existingRoot == null
          ? null
          : '${appSupportDir.path}/$existingRoot';
      final existingRootExists =
          existingRootPath != null && Directory(existingRootPath).existsSync();
      var etag = prefs.getString(_etagKey) ?? prefs.getString(_cacheTagKey);
      var lastModified = prefs.getString(_lastModifiedKey);
      if (!existingRootExists) {
        etag = null;
        lastModified = null;
      }

      final uri = Uri.parse(_zipUrl);
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        if (etag != null && etag.isNotEmpty) {
          request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
        } else if (lastModified != null && lastModified.isNotEmpty) {
          request.headers.set(HttpHeaders.ifModifiedSinceHeader, lastModified);
        }
        final response = await request.close();
        if (response.statusCode == HttpStatus.notModified &&
            existingRootPath != null &&
            existingRootExists) {
          return existingRootPath;
        }
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Failed to download tuner zip: ${response.statusCode}',
            uri: uri,
          );
        }

        final zipBytes = await consolidateHttpClientResponseBytes(response);
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final rootFolderName = _extractRootFolderName(archive);
        if (rootFolderName == null || rootFolderName.isEmpty) {
          throw StateError('ZIP archive did not contain a root folder.');
        }

        final rootPath = '${appSupportDir.path}/$rootFolderName';
        if (existingRootPath != null) {
          await Directory(existingRootPath).delete(recursive: true);
        }

        for (final file in archive) {
          final filePath = '${appSupportDir.path}/${file.name}';
          if (file.isFile) {
            final outputFile = File(filePath);
            outputFile.createSync(recursive: true);
            await outputFile.writeAsBytes(file.content as List<int>);
          } else {
            Directory(filePath).createSync(recursive: true);
          }
        }

        final responseEtag = response.headers.value(HttpHeaders.etagHeader);
        final responseLastModified =
            response.headers.value(HttpHeaders.lastModifiedHeader);
        await prefs.setString(_rootFolderKey, rootFolderName);
        await prefs.setString(_etagKey, responseEtag ?? '');
        await prefs.setString(_lastModifiedKey, responseLastModified ?? '');

        if (teamNumber != null) {
          await _updateTeamNumber(rootPath, teamNumber);
        }
        return rootPath;
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      debugPrint('Error ensuring tuner project is up to date: $error');
      rethrow;
    }
  }

  Future<String?> getLocalProjectPath() async {
    final prefs = await SharedPreferences.getInstance();
    final appSupportDir = await getApplicationSupportDirectory();
    final existingRoot = prefs.getString(_rootFolderKey);
    if (existingRoot == null || existingRoot.isEmpty) {
      return null;
    }
    final existingRootPath = '${appSupportDir.path}/$existingRoot';
    if (!Directory(existingRootPath).existsSync()) {
      return null;
    }
    return existingRootPath;
  }

  Future<String> useLocalProject({int? teamNumber}) async {
    final projectRoot = await getLocalProjectPath();
    if (projectRoot == null) {
      throw StateError('No local tuner project found.');
    }
    if (teamNumber != null) {
      await _updateTeamNumber(projectRoot, teamNumber);
    }
    return projectRoot;
  }

  Future<TunerProjectCheck> _checkRemoteStatus({
    required bool hasLocal,
    required String? etag,
    required String? lastModified,
  }) async {
    final uri = Uri.parse(_zipUrl);
    final client = HttpClient();
    try {
      final request = await client.headUrl(uri);
      if (hasLocal && etag != null && etag.isNotEmpty) {
        request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      } else if (hasLocal &&
          lastModified != null &&
          lastModified.isNotEmpty) {
        request.headers.set(HttpHeaders.ifModifiedSinceHeader, lastModified);
      }
      final response = await request.close();
      if (response.statusCode == HttpStatus.notModified) {
        return TunerProjectCheck(
          status: TunerProjectStatus.upToDate,
          hasLocal: hasLocal,
        );
      }
      if (response.statusCode == HttpStatus.ok) {
        return TunerProjectCheck(
          status: hasLocal
              ? TunerProjectStatus.updateAvailable
              : TunerProjectStatus.missing,
          hasLocal: hasLocal,
        );
      }
      throw HttpException(
        'Failed to check tuner zip: ${response.statusCode}',
        uri: uri,
      );
    } on SocketException {
      return TunerProjectCheck(
        status: TunerProjectStatus.offline,
        hasLocal: hasLocal,
      );
    } finally {
      client.close(force: true);
    }
  }

  String? _extractRootFolderName(Archive archive) {
    String? rootFolderName;
    for (final file in archive) {
      final parts = file.name.split('/');
      if (parts.isEmpty || parts.first.isEmpty) {
        continue;
      }
      rootFolderName ??= parts.first;
      if (rootFolderName != parts.first) {
        return rootFolderName;
      }
    }
    return rootFolderName;
  }

  Future<void> _updateTeamNumber(String projectRoot, int teamNumber) async {
    final teamFile =
        File('$projectRoot/.wpilib/wpilib_preferences.json');
    final teamJson = await json.decode(await teamFile.readAsString());
    teamJson["teamNumber"] = teamNumber;
    await teamFile
        .writeAsString(JsonEncoder.withIndent("    ").convert(teamJson));
  }
}

enum TunerProjectStatus {
  missing,
  updateAvailable,
  upToDate,
  offline,
}

class TunerProjectCheck {
  final TunerProjectStatus status;
  final bool hasLocal;

  const TunerProjectCheck({
    required this.status,
    required this.hasLocal,
  });
}
