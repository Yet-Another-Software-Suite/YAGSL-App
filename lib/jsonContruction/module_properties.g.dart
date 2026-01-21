// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModuleProperties _$ModulePropertiesFromJson(Map<String, dynamic> json) =>
    ModuleProperties(
      ConversionFactors.fromJson(
          json['conversionFactors'] as Map<String, dynamic>),
      CurrentLimit.fromJson(json['currentLimit'] as Map<String, dynamic>),
      RampRate.fromJson(json['rampRate'] as Map<String, dynamic>),
      (json['optimalVoltage'] as num).toInt(),
      (json['robotMass'] as num?)?.toDouble() ?? 0,
      (json['wheelGripCoefficientOfFriction'] as num).toDouble(),
    );

Map<String, dynamic> _$ModulePropertiesToJson(ModuleProperties instance) =>
    <String, dynamic>{
      'conversionFactors': instance.conversionFactors.toJson(),
      'currentLimit': instance.currentLimit.toJson(),
      'rampRate': instance.rampRate.toJson(),
      'optimalVoltage': instance.optimalVoltage,
      'robotMass': instance.robotMass,
      'wheelGripCoefficientOfFriction': instance.wheelGripCoefficientOfFriction,
    };
