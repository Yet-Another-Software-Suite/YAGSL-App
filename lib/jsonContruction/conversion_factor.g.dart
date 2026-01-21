// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversion_factor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversionFactors _$ConversionFactorsFromJson(Map<String, dynamic> json) =>
    ConversionFactors(
      AngleConversionFactor.fromJson(json['angle'] as Map<String, dynamic>),
      DriveConversionFactor.fromJson(json['drive'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConversionFactorsToJson(ConversionFactors instance) =>
    <String, dynamic>{
      'angle': instance.angle.toJson(),
      'drive': instance.drive.toJson(),
    };

AngleConversionFactor _$AngleConversionFactorFromJson(
        Map<String, dynamic> json) =>
    AngleConversionFactor(
      (json['gearRatio'] as num).toDouble(),
      (json['factor'] as num).toDouble(),
    );

Map<String, dynamic> _$AngleConversionFactorToJson(
        AngleConversionFactor instance) =>
    <String, dynamic>{
      'gearRatio': instance.gearRatio,
      'factor': instance.factor,
    };

DriveConversionFactor _$DriveConversionFactorFromJson(
        Map<String, dynamic> json) =>
    DriveConversionFactor(
      (json['gearRatio'] as num).toDouble(),
      (json['diameter'] as num).toDouble(),
      (json['factor'] as num).toDouble(),
    );

Map<String, dynamic> _$DriveConversionFactorToJson(
        DriveConversionFactor instance) =>
    <String, dynamic>{
      'gearRatio': instance.gearRatio,
      'diameter': instance.diameter,
      'factor': instance.factor,
    };
