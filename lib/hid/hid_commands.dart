// Commandes HID FOILS.
//
// Les valeurs sont les valeurs HID seules.
// La couche RUDP ajoute RUDP_CMD_APP (0x10).

abstract final class HidCommands {
  // ============================================================
  // HID COMMANDS
  // ============================================================

  static const int deviceNew = 0x00;
  static const int deviceDropped = 0x01;
  static const int deviceCreated = 0x02;
  static const int deviceClose = 0x03;
  static const int deviceFeature = 0x04;
  static const int deviceData = 0x05;
  static const int deviceGrab = 0x06;
  static const int deviceRelease = 0x07;
  static const int deviceSolicit = 0x08;

  // ============================================================
  // HID REPORT IDS
  // ============================================================

  static const int reportUnicode = 0x01;
  static const int reportKeyboard = 0x02;
  static const int reportConsumer = 0x03;
  static const int reportDesktop = 0x04;

  static bool isValidReportId(int reportId) {
    switch (reportId) {
      case reportUnicode:
      case reportKeyboard:
      case reportConsumer:
      case reportDesktop:
        return true;

      default:
        return false;
    }
  }
}
