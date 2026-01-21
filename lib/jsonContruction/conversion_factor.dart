import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'conversion_factor.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class ConversionFactors {
  ConversionFactors(this.angle, this.drive);

  AngleConversionFactor angle;
  DriveConversionFactor drive;

  factory ConversionFactors.fromJson(Map<String, dynamic> json) =>
      _$ConversionFactorsFromJson(json);

  Map<String, dynamic> toJson() => _$ConversionFactorsToJson(this);
}

@JsonSerializable()
class AngleConversionFactor {
  AngleConversionFactor(this.gearRatio, this.factor);

  double gearRatio;
  double factor;

  factory AngleConversionFactor.fromJson(Map<String, dynamic> json) =>
      _$AngleConversionFactorFromJson(json);

  Map<String, dynamic> toJson() => _$AngleConversionFactorToJson(this);
}

@JsonSerializable()
class DriveConversionFactor {
  DriveConversionFactor(this.gearRatio, this.diameter, this.factor);

  double gearRatio;
  double diameter;
  double factor;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory DriveConversionFactor.fromJson(Map<String, dynamic> json) =>
      _$DriveConversionFactorFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$DriveConversionFactorToJson(this);
}
