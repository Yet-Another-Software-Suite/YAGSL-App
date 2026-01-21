// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) => Module(
      Location.fromJson(json['location'] as Map<String, dynamic>),
      (json['absoluteEncoderOffset'] as num).toDouble(),
      Drive.fromJson(json['drive'] as Map<String, dynamic>),
      Angle.fromJson(json['angle'] as Map<String, dynamic>),
      ModuleEncoder.fromJson(json['encoder'] as Map<String, dynamic>),
      Inverted.fromJson(json['inverted'] as Map<String, dynamic>),
      json['absoluteEncoderInverted'] as bool?,
    );

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
      'location': instance.location.toJson(),
      'absoluteEncoderOffset': instance.absoluteEncoderOffset,
      'drive': instance.drive.toJson(),
      'angle': instance.angle.toJson(),
      'encoder': instance.encoder.toJson(),
      'inverted': instance.inverted.toJson(),
      'absoluteEncoderInverted': instance.absoluteEncoderInverted,
    };
