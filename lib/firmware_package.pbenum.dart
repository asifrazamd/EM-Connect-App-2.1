//
//  Generated code. Do not modify.
//  source: firmware_package.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Encryption_Type extends $pb.ProtobufEnum {
  static const Encryption_Type NO_ENC = Encryption_Type._(0, _omitEnumNames ? '' : 'NO_ENC');
  static const Encryption_Type AES_ECB = Encryption_Type._(1, _omitEnumNames ? '' : 'AES_ECB');
  static const Encryption_Type AES_CBC = Encryption_Type._(2, _omitEnumNames ? '' : 'AES_CBC');
  static const Encryption_Type AES_CTR = Encryption_Type._(3, _omitEnumNames ? '' : 'AES_CTR');

  static const $core.List<Encryption_Type> values = <Encryption_Type> [
    NO_ENC,
    AES_ECB,
    AES_CBC,
    AES_CTR,
  ];

  static final $core.Map<$core.int, Encryption_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Encryption_Type? valueOf($core.int value) => _byValue[value];

  const Encryption_Type._($core.int v, $core.String n) : super(v, n);
}

class Section_Code extends $pb.ProtobufEnum {
  static const Section_Code FirmwareUpdater = Section_Code._(0, _omitEnumNames ? '' : 'FirmwareUpdater');
  static const Section_Code EM_Core = Section_Code._(1, _omitEnumNames ? '' : 'EM_Core');
  static const Section_Code CustomerApp = Section_Code._(3, _omitEnumNames ? '' : 'CustomerApp');
  static const Section_Code Bootloader = Section_Code._(4, _omitEnumNames ? '' : 'Bootloader');

  static const $core.List<Section_Code> values = <Section_Code> [
    FirmwareUpdater,
    EM_Core,
    CustomerApp,
    Bootloader,
  ];

  static final $core.Map<$core.int, Section_Code> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Section_Code? valueOf($core.int value) => _byValue[value];

  const Section_Code._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
