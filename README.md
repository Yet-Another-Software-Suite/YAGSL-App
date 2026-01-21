# YAGSL Configurator

YAGSL Configurator is a Flutter desktop app for building, validating, and
exporting swerve drive configuration for Yet Another Generic Swerve Library
(YAGSL). It supports simulator workflows and real-robot workflows via
NetworkTables and SSH.

## Features

- Guided configuration with validation for all swerve and module settings
- Export/import of swerve JSON configs in standard YAGSL deploy layout
- Robot tests and utilities (offset capture, drivebase tests)
- Simulator support with automatic Gradle wrapper execution
- Live log view for Gradle tasks and robot log tailing (SSH)

## Desktop targets

Windows, Linux, and macOS builds are supported. CI is configured for Windows
and Linux; macOS builds can be re-enabled when needed.

## Getting started

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter build windows
flutter build linux
flutter build macos
```

## Tests

```bash
flutter analyze
flutter test
```

## Config export layout

Exported ZIPs use the standard YAGSL deploy layout:

```
swerve/
  controllerproperties.json
  swervedrive.json
  modules/
    backleft.json
    backright.json
    frontleft.json
    frontright.json
    physicalproperties.json
    pidfproperties.json
```

## License

MIT. See `LICENSE`.
