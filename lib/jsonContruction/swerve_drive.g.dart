// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swerve_drive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwerveDrive _$SwerveDriveFromJson(Map<String, dynamic> json) => SwerveDrive(
      Imu.fromJson(json['imu'] as Map<String, dynamic>),
      json['invertedIMU'] as bool,
    )
      ..schema = json[r'$schema'] as String?
      ..modules =
          (json['modules'] as List<dynamic>).map((e) => e as String).toList();

Map<String, dynamic> _$SwerveDriveToJson(SwerveDrive instance) =>
    <String, dynamic>{
      r'$schema': instance.schema,
      'imu': instance.imu.toJson(),
      'invertedIMU': instance.invertedIMU,
      'modules': instance.modules,
    };
