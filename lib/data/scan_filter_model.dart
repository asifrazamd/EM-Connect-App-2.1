class ScanFilterModel {
  String macAddr = "";
  int rssiVal = -100;

  ScanFilterModel(String mac, int rssi) {
    macAddr = mac;
    rssiVal = rssi;
  }
}
