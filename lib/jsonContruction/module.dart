import 'package:json_annotation/json_annotation.dart';
import 'package:yagsl_app/jsonContruction/angle.dart';
import 'package:yagsl_app/jsonContruction/drive.dart';
import 'package:yagsl_app/jsonContruction/module_encoder.dart';
import 'package:yagsl_app/jsonContruction/inverted.dart';
import 'package:yagsl_app/jsonContruction/location.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'module.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class Module {
  Module(
    this.location,
    this.absoluteEncoderOffset,
    this.drive,
    this.angle,
    this.encoder,
    this.inverted, [
    this.absoluteEncoderInverted,
  ]);

  Location location;
  double absoluteEncoderOffset;
  Drive drive;
  Angle angle;
  ModuleEncoder encoder;
  Inverted inverted;
  bool? absoluteEncoderInverted;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ModuleToJson(this);
}
