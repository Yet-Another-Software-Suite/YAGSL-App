import 'package:json_annotation/json_annotation.dart';
import 'package:yagsl_app/jsonContruction/conversion_factor.dart';
import 'package:yagsl_app/jsonContruction/current_limit.dart';
import 'package:yagsl_app/jsonContruction/ramp_rate.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'module_properties.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class ModuleProperties {
  ModuleProperties(
    this.conversionFactors,
    this.currentLimit,
    this.rampRate,
    this.optimalVoltage,
    this.robotMass,
    this.wheelGripCoefficientOfFriction,
  );

  ConversionFactors conversionFactors;
  CurrentLimit currentLimit;
  RampRate rampRate;
  int optimalVoltage;
  @JsonKey(defaultValue: 0)
  double robotMass;
  double wheelGripCoefficientOfFriction;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory ModuleProperties.fromJson(Map<String, dynamic> json) => _$ModulePropertiesFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ModulePropertiesToJson(this);
}
