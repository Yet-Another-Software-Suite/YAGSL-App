import 'package:json_annotation/json_annotation.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'controller_properties.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class ControllerProperties {
  ControllerProperties(this.angleJoystickRadiusDeadband, this.heading);

  double angleJoystickRadiusDeadband;
  Heading heading;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory ControllerProperties.fromJson(Map<String, dynamic> json) =>
      _$ControllerPropertiesFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ControllerPropertiesToJson(this);
}

@JsonSerializable()
class Heading {
  Heading(this.p, this.i, this.d);

  double p;
  double i;
  double d;

  factory Heading.fromJson(Map<String, dynamic> json) =>
      _$HeadingFromJson(json);

  Map<String, dynamic> toJson() => _$HeadingToJson(this);
}
