// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ControllerProperties _$ControllerPropertiesFromJson(
        Map<String, dynamic> json) =>
    ControllerProperties(
      (json['angleJoystickRadiusDeadband'] as num).toDouble(),
      Heading.fromJson(json['heading'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ControllerPropertiesToJson(
        ControllerProperties instance) =>
    <String, dynamic>{
      'angleJoystickRadiusDeadband': instance.angleJoystickRadiusDeadband,
      'heading': instance.heading.toJson(),
    };

Heading _$HeadingFromJson(Map<String, dynamic> json) => Heading(
      (json['p'] as num).toDouble(),
      (json['i'] as num).toDouble(),
      (json['d'] as num).toDouble(),
    );

Map<String, dynamic> _$HeadingToJson(Heading instance) => <String, dynamic>{
      'p': instance.p,
      'i': instance.i,
      'd': instance.d,
    };
