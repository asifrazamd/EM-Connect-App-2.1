import 'package:universal_ble/universal_ble.dart';

class BeaconTunerService {
  late BleService service;
  late BleCharacteristic beaconTunerChar;
}

class FirmwareUpdateService {
  late BleService service;
  late BleCharacteristic controlPointChar;
  late BleCharacteristic dataChar;
}
