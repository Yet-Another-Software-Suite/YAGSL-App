import 'package:json_annotation/json_annotation.dart';
import 'package:yagsl_app/jsonContruction/imu.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'swerve_drive.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable(explicitToJson: true)
class SwerveDrive {
  SwerveDrive(this.imu, this.invertedIMU);

  @JsonKey(name: r'$schema')
  String? schema;
  Imu imu;
  bool invertedIMU;
  List<String> modules = [
    "frontleft.json",
    "frontright.json",
    "backleft.json",
    "backright.json"
  ];

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory SwerveDrive.fromJson(Map<String, dynamic> json) => _$SwerveDriveFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SwerveDriveToJson(this);
}
