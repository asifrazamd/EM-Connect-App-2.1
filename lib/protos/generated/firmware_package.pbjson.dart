//
//  Generated code. Do not modify.
//  source: firmware_package.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use encryption_TypeDescriptor instead')
const Encryption_Type$json = {
  '1': 'Encryption_Type',
  '2': [
    {'1': 'NO_ENC', '2': 0},
    {'1': 'AES_ECB', '2': 1},
    {'1': 'AES_CBC', '2': 2},
    {'1': 'AES_CTR', '2': 3},
  ],
};

/// Descriptor for `Encryption_Type`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List encryption_TypeDescriptor = $convert.base64Decode(
    'Cg9FbmNyeXB0aW9uX1R5cGUSCgoGTk9fRU5DEAASCwoHQUVTX0VDQhABEgsKB0FFU19DQkMQAh'
    'ILCgdBRVNfQ1RSEAM=');

@$core.Deprecated('Use section_CodeDescriptor instead')
const Section_Code$json = {
  '1': 'Section_Code',
  '2': [
    {'1': 'FirmwareUpdater', '2': 0},
    {'1': 'EM_Core', '2': 1},
    {'1': 'CustomerApp', '2': 3},
    {'1': 'Bootloader', '2': 4},
  ],
};

/// Descriptor for `Section_Code`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List section_CodeDescriptor = $convert.base64Decode(
    'CgxTZWN0aW9uX0NvZGUSEwoPRmlybXdhcmVVcGRhdGVyEAASCwoHRU1fQ29yZRABEg8KC0N1c3'
    'RvbWVyQXBwEAMSDgoKQm9vdGxvYWRlchAE');

@$core.Deprecated('Use silicon_InfoDescriptor instead')
const Silicon_Info$json = {
  '1': 'Silicon_Info',
  '2': [
    {'1': 'silicon_rev', '3': 1, '4': 1, '5': 13, '10': 'siliconRev'},
    {'1': 'silicon_type', '3': 2, '4': 1, '5': 13, '10': 'siliconType'},
  ],
};

/// Descriptor for `Silicon_Info`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List silicon_InfoDescriptor = $convert.base64Decode(
    'CgxTaWxpY29uX0luZm8SHwoLc2lsaWNvbl9yZXYYASABKA1SCnNpbGljb25SZXYSIQoMc2lsaW'
    'Nvbl90eXBlGAIgASgNUgtzaWxpY29uVHlwZQ==');

@$core.Deprecated('Use target_InformationDescriptor instead')
const Target_Information$json = {
  '1': 'Target_Information',
  '2': [
    {'1': 'silicon_info', '3': 1, '4': 1, '5': 11, '6': '.em_fw_package.Silicon_Info', '10': 'siliconInfo'},
    {'1': 'product_id', '3': 2, '4': 1, '5': 9, '10': 'productId'},
  ],
};

/// Descriptor for `Target_Information`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List target_InformationDescriptor = $convert.base64Decode(
    'ChJUYXJnZXRfSW5mb3JtYXRpb24SPgoMc2lsaWNvbl9pbmZvGAEgASgLMhsuZW1fZndfcGFja2'
    'FnZS5TaWxpY29uX0luZm9SC3NpbGljb25JbmZvEh0KCnByb2R1Y3RfaWQYAiABKAlSCXByb2R1'
    'Y3RJZA==');

@$core.Deprecated('Use fW_HeaderDescriptor instead')
const FW_Header$json = {
  '1': 'FW_Header',
  '2': [
    {'1': 'hdr_ver', '3': 1, '4': 1, '5': 13, '10': 'hdrVer'},
    {'1': 'hdr_len', '3': 2, '4': 1, '5': 13, '10': 'hdrLen'},
    {'1': 'section_code', '3': 3, '4': 1, '5': 14, '6': '.em_fw_package.Section_Code', '10': 'sectionCode'},
    {'1': 'fw_start_addr', '3': 4, '4': 1, '5': 13, '10': 'fwStartAddr'},
    {'1': 'fw_size', '3': 5, '4': 1, '5': 13, '10': 'fwSize'},
    {'1': 'fw_crc', '3': 6, '4': 1, '5': 13, '10': 'fwCrc'},
    {'1': 'emcore_crc', '3': 7, '4': 1, '5': 13, '10': 'emcoreCrc'},
    {'1': 'fw_options', '3': 8, '4': 1, '5': 13, '10': 'fwOptions'},
    {'1': 'fw_ver', '3': 9, '4': 1, '5': 13, '10': 'fwVer'},
    {'1': 'fw_exec_addr', '3': 10, '4': 1, '5': 13, '10': 'fwExecAddr'},
    {'1': 'hdr_crc', '3': 11, '4': 1, '5': 13, '10': 'hdrCrc'},
  ],
};

/// Descriptor for `FW_Header`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fW_HeaderDescriptor = $convert.base64Decode(
    'CglGV19IZWFkZXISFwoHaGRyX3ZlchgBIAEoDVIGaGRyVmVyEhcKB2hkcl9sZW4YAiABKA1SBm'
    'hkckxlbhI+CgxzZWN0aW9uX2NvZGUYAyABKA4yGy5lbV9md19wYWNrYWdlLlNlY3Rpb25fQ29k'
    'ZVILc2VjdGlvbkNvZGUSIgoNZndfc3RhcnRfYWRkchgEIAEoDVILZndTdGFydEFkZHISFwoHZn'
    'dfc2l6ZRgFIAEoDVIGZndTaXplEhUKBmZ3X2NyYxgGIAEoDVIFZndDcmMSHQoKZW1jb3JlX2Ny'
    'YxgHIAEoDVIJZW1jb3JlQ3JjEh0KCmZ3X29wdGlvbnMYCCABKA1SCWZ3T3B0aW9ucxIVCgZmd1'
    '92ZXIYCSABKA1SBWZ3VmVyEiAKDGZ3X2V4ZWNfYWRkchgKIAEoDVIKZndFeGVjQWRkchIXCgdo'
    'ZHJfY3JjGAsgASgNUgZoZHJDcmM=');

@$core.Deprecated('Use fW_SignatureDescriptor instead')
const FW_Signature$json = {
  '1': 'FW_Signature',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 12, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 12, '10': 'y'},
  ],
};

/// Descriptor for `FW_Signature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fW_SignatureDescriptor = $convert.base64Decode(
    'CgxGV19TaWduYXR1cmUSDAoBeBgBIAEoDFIBeBIMCgF5GAIgASgMUgF5');

@$core.Deprecated('Use fW_ElementDescriptor instead')
const FW_Element$json = {
  '1': 'FW_Element',
  '2': [
    {'1': 'fw_hdr', '3': 1, '4': 1, '5': 11, '6': '.em_fw_package.FW_Header', '10': 'fwHdr'},
    {'1': 'fw_hdr_raw', '3': 2, '4': 1, '5': 12, '10': 'fwHdrRaw'},
    {'1': 'fw_code_raw', '3': 3, '4': 1, '5': 12, '10': 'fwCodeRaw'},
    {'1': 'fw_signature', '3': 4, '4': 1, '5': 11, '6': '.em_fw_package.FW_Signature', '10': 'fwSignature'},
    {'1': 'enc_type', '3': 5, '4': 1, '5': 14, '6': '.em_fw_package.Encryption_Type', '10': 'encType'},
    {'1': 'crypto_init_data', '3': 6, '4': 1, '5': 12, '10': 'cryptoInitData'},
    {'1': 'digest', '3': 7, '4': 1, '5': 12, '10': 'digest'},
  ],
};

/// Descriptor for `FW_Element`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fW_ElementDescriptor = $convert.base64Decode(
    'CgpGV19FbGVtZW50Ei8KBmZ3X2hkchgBIAEoCzIYLmVtX2Z3X3BhY2thZ2UuRldfSGVhZGVyUg'
    'Vmd0hkchIcCgpmd19oZHJfcmF3GAIgASgMUghmd0hkclJhdxIeCgtmd19jb2RlX3JhdxgDIAEo'
    'DFIJZndDb2RlUmF3Ej4KDGZ3X3NpZ25hdHVyZRgEIAEoCzIbLmVtX2Z3X3BhY2thZ2UuRldfU2'
    'lnbmF0dXJlUgtmd1NpZ25hdHVyZRI5CghlbmNfdHlwZRgFIAEoDjIeLmVtX2Z3X3BhY2thZ2Uu'
    'RW5jcnlwdGlvbl9UeXBlUgdlbmNUeXBlEigKEGNyeXB0b19pbml0X2RhdGEYBiABKAxSDmNyeX'
    'B0b0luaXREYXRhEhYKBmRpZ2VzdBgHIAEoDFIGZGlnZXN0');

@$core.Deprecated('Use fW_PackageDescriptor instead')
const FW_Package$json = {
  '1': 'FW_Package',
  '2': [
    {'1': 'fw_count', '3': 1, '4': 1, '5': 13, '10': 'fwCount'},
    {'1': 'target_info', '3': 2, '4': 1, '5': 11, '6': '.em_fw_package.Target_Information', '10': 'targetInfo'},
    {'1': 'fw_elements', '3': 3, '4': 3, '5': 11, '6': '.em_fw_package.FW_Element', '10': 'fwElements'},
  ],
};

/// Descriptor for `FW_Package`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fW_PackageDescriptor = $convert.base64Decode(
    'CgpGV19QYWNrYWdlEhkKCGZ3X2NvdW50GAEgASgNUgdmd0NvdW50EkIKC3RhcmdldF9pbmZvGA'
    'IgASgLMiEuZW1fZndfcGFja2FnZS5UYXJnZXRfSW5mb3JtYXRpb25SCnRhcmdldEluZm8SOgoL'
    'ZndfZWxlbWVudHMYAyADKAsyGS5lbV9md19wYWNrYWdlLkZXX0VsZW1lbnRSCmZ3RWxlbWVudH'
    'M=');

