class HidDevice {
  const HidDevice({
    required this.deviceId,
    required this.name,
    required this.serial,
    required this.reportUnicode,
    required this.reportKeyboard,
    required this.reportConsumer,
    required this.reportSystem,
  });

  // ============================================================
  // IDENTITE DU PERIPHERIQUE
  // ============================================================

  final int deviceId;

  final String name;

  final String serial;

  // ============================================================
  // REPORT IDS
  // ============================================================

  final int reportUnicode;

  final int reportKeyboard;

  final int reportConsumer;

  final int reportSystem;

  // ============================================================
  // FREEBOX REMOTE
  // ============================================================

  static const HidDevice freeboxRemote = HidDevice(
    deviceId: 1,
    name: 'FreeboxRemote',
    serial: 'FreeboxRemote-001',
    reportUnicode: 1,
    reportKeyboard: 2,
    reportConsumer: 3,
    reportSystem: 4,
  );

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'HidDevice('
        'deviceId: $deviceId, '
        'name: $name, '
        'serial: $serial, '
        'reportUnicode: $reportUnicode, '
        'reportKeyboard: $reportKeyboard, '
        'reportConsumer: $reportConsumer, '
        'reportSystem: $reportSystem'
        ')';
  }
}
