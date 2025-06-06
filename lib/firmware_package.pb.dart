import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'firmware_package.pbenum.dart';

export 'firmware_package.pbenum.dart';

class Silicon_Info extends $pb.GeneratedMessage {
  factory Silicon_Info({
    $core.int? siliconRev,
    $core.int? siliconType,
  }) {
    final $result = create();
    if (siliconRev != null) {
      $result.siliconRev = siliconRev;
    }
    if (siliconType != null) {
      $result.siliconType = siliconType;
    }
    return $result;
  }
  Silicon_Info._() : super();
  factory Silicon_Info.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Silicon_Info.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Silicon_Info',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'siliconRev', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'siliconType', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Silicon_Info clone() => Silicon_Info()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Silicon_Info copyWith(void Function(Silicon_Info) updates) =>
      super.copyWith((message) => updates(message as Silicon_Info))
          as Silicon_Info;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Silicon_Info create() => Silicon_Info._();
  Silicon_Info createEmptyInstance() => create();
  static $pb.PbList<Silicon_Info> createRepeated() =>
      $pb.PbList<Silicon_Info>();
  @$core.pragma('dart2js:noInline')
  static Silicon_Info getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Silicon_Info>(create);
  static Silicon_Info? _defaultInstance;

  /// Silicon Revision field corresponds to the Design Iteration
  @$pb.TagNumber(1)
  $core.int get siliconRev => $_getIZ(0);
  @$pb.TagNumber(1)
  set siliconRev($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSiliconRev() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiliconRev() => clearField(1);

  /// Silicon Type field corresponds to the IC identification code (e.g., 9305)
  @$pb.TagNumber(2)
  $core.int get siliconType => $_getIZ(1);
  @$pb.TagNumber(2)
  set siliconType($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSiliconType() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiliconType() => clearField(2);
}

class Target_Information extends $pb.GeneratedMessage {
  factory Target_Information({
    Silicon_Info? siliconInfo,
    $core.String? productId,
  }) {
    final $result = create();
    if (siliconInfo != null) {
      $result.siliconInfo = siliconInfo;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    return $result;
  }
  Target_Information._() : super();
  factory Target_Information.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Target_Information.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Target_Information',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..aOM<Silicon_Info>(1, _omitFieldNames ? '' : 'siliconInfo',
        subBuilder: Silicon_Info.create)
    ..aOS(2, _omitFieldNames ? '' : 'productId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Target_Information clone() => Target_Information()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Target_Information copyWith(void Function(Target_Information) updates) =>
      super.copyWith((message) => updates(message as Target_Information))
          as Target_Information;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Target_Information create() => Target_Information._();
  Target_Information createEmptyInstance() => create();
  static $pb.PbList<Target_Information> createRepeated() =>
      $pb.PbList<Target_Information>();
  @$core.pragma('dart2js:noInline')
  static Target_Information getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Target_Information>(create);
  static Target_Information? _defaultInstance;

  @$pb.TagNumber(1)
  Silicon_Info get siliconInfo => $_getN(0);
  @$pb.TagNumber(1)
  set siliconInfo(Silicon_Info v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSiliconInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiliconInfo() => clearField(1);
  @$pb.TagNumber(1)
  Silicon_Info ensureSiliconInfo() => $_ensure(0);

  /// product name field represents the name of the end product name (e.g., EMBC0x)
  @$pb.TagNumber(2)
  $core.String get productId => $_getSZ(1);
  @$pb.TagNumber(2)
  set productId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProductId() => clearField(2);
}

class FW_Header extends $pb.GeneratedMessage {
  factory FW_Header({
    $core.int? hdrVer,
    $core.int? hdrLen,
    Section_Code? sectionCode,
    $core.int? fwStartAddr,
    $core.int? fwSize,
    $core.int? fwCrc,
    $core.int? emcoreCrc,
    $core.int? fwOptions,
    $core.int? fwVer,
    $core.int? fwExecAddr,
    $core.int? hdrCrc,
  }) {
    final $result = create();
    if (hdrVer != null) {
      $result.hdrVer = hdrVer;
    }
    if (hdrLen != null) {
      $result.hdrLen = hdrLen;
    }
    if (sectionCode != null) {
      $result.sectionCode = sectionCode;
    }
    if (fwStartAddr != null) {
      $result.fwStartAddr = fwStartAddr;
    }
    if (fwSize != null) {
      $result.fwSize = fwSize;
    }
    if (fwCrc != null) {
      $result.fwCrc = fwCrc;
    }
    if (emcoreCrc != null) {
      $result.emcoreCrc = emcoreCrc;
    }
    if (fwOptions != null) {
      $result.fwOptions = fwOptions;
    }
    if (fwVer != null) {
      $result.fwVer = fwVer;
    }
    if (fwExecAddr != null) {
      $result.fwExecAddr = fwExecAddr;
    }
    if (hdrCrc != null) {
      $result.hdrCrc = hdrCrc;
    }
    return $result;
  }
  FW_Header._() : super();
  factory FW_Header.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FW_Header.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FW_Header',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'hdrVer', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'hdrLen', $pb.PbFieldType.OU3)
    ..e<Section_Code>(
        3, _omitFieldNames ? '' : 'sectionCode', $pb.PbFieldType.OE,
        defaultOrMaker: Section_Code.FirmwareUpdater,
        valueOf: Section_Code.valueOf,
        enumValues: Section_Code.values)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'fwStartAddr', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'fwSize', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'fwCrc', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'emcoreCrc', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'fwOptions', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'fwVer', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'fwExecAddr', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'hdrCrc', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FW_Header clone() => FW_Header()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FW_Header copyWith(void Function(FW_Header) updates) =>
      super.copyWith((message) => updates(message as FW_Header)) as FW_Header;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FW_Header create() => FW_Header._();
  FW_Header createEmptyInstance() => create();
  static $pb.PbList<FW_Header> createRepeated() => $pb.PbList<FW_Header>();
  @$core.pragma('dart2js:noInline')
  static FW_Header getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FW_Header>(create);
  static FW_Header? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get hdrVer => $_getIZ(0);
  @$pb.TagNumber(1)
  set hdrVer($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHdrVer() => $_has(0);
  @$pb.TagNumber(1)
  void clearHdrVer() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get hdrLen => $_getIZ(1);
  @$pb.TagNumber(2)
  set hdrLen($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasHdrLen() => $_has(1);
  @$pb.TagNumber(2)
  void clearHdrLen() => clearField(2);

  @$pb.TagNumber(3)
  Section_Code get sectionCode => $_getN(2);
  @$pb.TagNumber(3)
  set sectionCode(Section_Code v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSectionCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearSectionCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get fwStartAddr => $_getIZ(3);
  @$pb.TagNumber(4)
  set fwStartAddr($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasFwStartAddr() => $_has(3);
  @$pb.TagNumber(4)
  void clearFwStartAddr() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get fwSize => $_getIZ(4);
  @$pb.TagNumber(5)
  set fwSize($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasFwSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearFwSize() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get fwCrc => $_getIZ(5);
  @$pb.TagNumber(6)
  set fwCrc($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasFwCrc() => $_has(5);
  @$pb.TagNumber(6)
  void clearFwCrc() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get emcoreCrc => $_getIZ(6);
  @$pb.TagNumber(7)
  set emcoreCrc($core.int v) {
    $_setUnsignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasEmcoreCrc() => $_has(6);
  @$pb.TagNumber(7)
  void clearEmcoreCrc() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get fwOptions => $_getIZ(7);
  @$pb.TagNumber(8)
  set fwOptions($core.int v) {
    $_setUnsignedInt32(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasFwOptions() => $_has(7);
  @$pb.TagNumber(8)
  void clearFwOptions() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get fwVer => $_getIZ(8);
  @$pb.TagNumber(9)
  set fwVer($core.int v) {
    $_setUnsignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasFwVer() => $_has(8);
  @$pb.TagNumber(9)
  void clearFwVer() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get fwExecAddr => $_getIZ(9);
  @$pb.TagNumber(10)
  set fwExecAddr($core.int v) {
    $_setUnsignedInt32(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasFwExecAddr() => $_has(9);
  @$pb.TagNumber(10)
  void clearFwExecAddr() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get hdrCrc => $_getIZ(10);
  @$pb.TagNumber(11)
  set hdrCrc($core.int v) {
    $_setUnsignedInt32(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasHdrCrc() => $_has(10);
  @$pb.TagNumber(11)
  void clearHdrCrc() => clearField(11);
}

class FW_Signature extends $pb.GeneratedMessage {
  factory FW_Signature({
    $core.List<$core.int>? x,
    $core.List<$core.int>? y,
  }) {
    final $result = create();
    if (x != null) {
      $result.x = x;
    }
    if (y != null) {
      $result.y = y;
    }
    return $result;
  }
  FW_Signature._() : super();
  factory FW_Signature.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FW_Signature.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FW_Signature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'x', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'y', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FW_Signature clone() => FW_Signature()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FW_Signature copyWith(void Function(FW_Signature) updates) =>
      super.copyWith((message) => updates(message as FW_Signature))
          as FW_Signature;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FW_Signature create() => FW_Signature._();
  FW_Signature createEmptyInstance() => create();
  static $pb.PbList<FW_Signature> createRepeated() =>
      $pb.PbList<FW_Signature>();
  @$core.pragma('dart2js:noInline')
  static FW_Signature getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FW_Signature>(create);
  static FW_Signature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => clearField(2);
}

class FW_Element extends $pb.GeneratedMessage {
  factory FW_Element({
    FW_Header? fwHdr,
    $core.List<$core.int>? fwHdrRaw,
    $core.List<$core.int>? fwCodeRaw,
    FW_Signature? fwSignature,
    Encryption_Type? encType,
    $core.List<$core.int>? cryptoInitData,
    $core.List<$core.int>? digest,
  }) {
    final $result = create();
    if (fwHdr != null) {
      $result.fwHdr = fwHdr;
    }
    if (fwHdrRaw != null) {
      $result.fwHdrRaw = fwHdrRaw;
    }
    if (fwCodeRaw != null) {
      $result.fwCodeRaw = fwCodeRaw;
    }
    if (fwSignature != null) {
      $result.fwSignature = fwSignature;
    }
    if (encType != null) {
      $result.encType = encType;
    }
    if (cryptoInitData != null) {
      $result.cryptoInitData = cryptoInitData;
    }
    if (digest != null) {
      $result.digest = digest;
    }
    return $result;
  }
  FW_Element._() : super();
  factory FW_Element.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FW_Element.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FW_Element',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..aOM<FW_Header>(1, _omitFieldNames ? '' : 'fwHdr',
        subBuilder: FW_Header.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'fwHdrRaw', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'fwCodeRaw', $pb.PbFieldType.OY)
    ..aOM<FW_Signature>(4, _omitFieldNames ? '' : 'fwSignature',
        subBuilder: FW_Signature.create)
    ..e<Encryption_Type>(
        5, _omitFieldNames ? '' : 'encType', $pb.PbFieldType.OE,
        defaultOrMaker: Encryption_Type.NO_ENC,
        valueOf: Encryption_Type.valueOf,
        enumValues: Encryption_Type.values)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'cryptoInitData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'digest', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FW_Element clone() => FW_Element()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FW_Element copyWith(void Function(FW_Element) updates) =>
      super.copyWith((message) => updates(message as FW_Element)) as FW_Element;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FW_Element create() => FW_Element._();
  FW_Element createEmptyInstance() => create();
  static $pb.PbList<FW_Element> createRepeated() => $pb.PbList<FW_Element>();
  @$core.pragma('dart2js:noInline')
  static FW_Element getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FW_Element>(create);
  static FW_Element? _defaultInstance;

  @$pb.TagNumber(1)
  FW_Header get fwHdr => $_getN(0);
  @$pb.TagNumber(1)
  set fwHdr(FW_Header v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFwHdr() => $_has(0);
  @$pb.TagNumber(1)
  void clearFwHdr() => clearField(1);
  @$pb.TagNumber(1)
  FW_Header ensureFwHdr() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get fwHdrRaw => $_getN(1);
  @$pb.TagNumber(2)
  set fwHdrRaw($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFwHdrRaw() => $_has(1);
  @$pb.TagNumber(2)
  void clearFwHdrRaw() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get fwCodeRaw => $_getN(2);
  @$pb.TagNumber(3)
  set fwCodeRaw($core.List<$core.int> v) {
    $_setBytes(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFwCodeRaw() => $_has(2);
  @$pb.TagNumber(3)
  void clearFwCodeRaw() => clearField(3);

  @$pb.TagNumber(4)
  FW_Signature get fwSignature => $_getN(3);
  @$pb.TagNumber(4)
  set fwSignature(FW_Signature v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasFwSignature() => $_has(3);
  @$pb.TagNumber(4)
  void clearFwSignature() => clearField(4);
  @$pb.TagNumber(4)
  FW_Signature ensureFwSignature() => $_ensure(3);

  @$pb.TagNumber(5)
  Encryption_Type get encType => $_getN(4);
  @$pb.TagNumber(5)
  set encType(Encryption_Type v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEncType() => $_has(4);
  @$pb.TagNumber(5)
  void clearEncType() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get cryptoInitData => $_getN(5);
  @$pb.TagNumber(6)
  set cryptoInitData($core.List<$core.int> v) {
    $_setBytes(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCryptoInitData() => $_has(5);
  @$pb.TagNumber(6)
  void clearCryptoInitData() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get digest => $_getN(6);
  @$pb.TagNumber(7)
  set digest($core.List<$core.int> v) {
    $_setBytes(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDigest() => $_has(6);
  @$pb.TagNumber(7)
  void clearDigest() => clearField(7);
}

class FW_Package extends $pb.GeneratedMessage {
  factory FW_Package({
    $core.int? fwCount,
    Target_Information? targetInfo,
    $core.Iterable<FW_Element>? fwElements,
  }) {
    final $result = create();
    if (fwCount != null) {
      $result.fwCount = fwCount;
    }
    if (targetInfo != null) {
      $result.targetInfo = targetInfo;
    }
    if (fwElements != null) {
      $result.fwElements.addAll(fwElements);
    }
    return $result;
  }
  FW_Package._() : super();
  factory FW_Package.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FW_Package.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FW_Package',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'em_fw_package'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'fwCount', $pb.PbFieldType.OU3)
    ..aOM<Target_Information>(2, _omitFieldNames ? '' : 'targetInfo',
        subBuilder: Target_Information.create)
    ..pc<FW_Element>(3, _omitFieldNames ? '' : 'fwElements', $pb.PbFieldType.PM,
        subBuilder: FW_Element.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FW_Package clone() => FW_Package()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FW_Package copyWith(void Function(FW_Package) updates) =>
      super.copyWith((message) => updates(message as FW_Package)) as FW_Package;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FW_Package create() => FW_Package._();
  FW_Package createEmptyInstance() => create();
  static $pb.PbList<FW_Package> createRepeated() => $pb.PbList<FW_Package>();
  @$core.pragma('dart2js:noInline')
  static FW_Package getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FW_Package>(create);
  static FW_Package? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fwCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set fwCount($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFwCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearFwCount() => clearField(1);

  @$pb.TagNumber(2)
  Target_Information get targetInfo => $_getN(1);
  @$pb.TagNumber(2)
  set targetInfo(Target_Information v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTargetInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetInfo() => clearField(2);
  @$pb.TagNumber(2)
  Target_Information ensureTargetInfo() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<FW_Element> get fwElements => $_getList(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
