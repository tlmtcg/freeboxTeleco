import 'dart:typed_data';

import 'commands/hid_data.dart';
import 'hid_commands.dart';
import 'hid_sender.dart';
import 'hid_state.dart';
import 'hid_validator.dart';

class HidReportSender {
  HidReportSender({required this.sender, required this.state});

  final HidSender sender;
  final HidState state;

  static const int deviceId = 1;

  // ============================================================
  // KEYBOARD
  // ============================================================

  Future<void> sendKeyboard(int keyCode) async {
    final report = <int>[keyCode & 0xFF, 0x00];

    await _send(HidCommands.reportKeyboard, report);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    await _send(HidCommands.reportKeyboard, const <int>[0x00, 0x00]);
  }

  // ============================================================
  // CONSUMER
  // ============================================================

  Future<void> sendConsumer(int usage) async {
    final report = Uint8List(2);

    final data = ByteData.sublistView(report);

    data.setUint16(0, usage, Endian.little);

    await _send(HidCommands.reportConsumer, report);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    await _send(HidCommands.reportConsumer, const <int>[0x00, 0x00]);
  }

  // ============================================================
  // DESKTOP / SYSTEM
  // ============================================================

  Future<void> sendDesktop(int usage) async {
    final report = Uint8List(1);

    report[0] = usage & 0xFF;

    await _send(HidCommands.reportDesktop, report);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    await _send(HidCommands.reportDesktop, const <int>[0x00]);
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _send(int reportId, List<int> report) async {
    if (!sender.rudp.isConnected) {
      throw StateError('RUDP non connecté.');
    }

    if (!state.isRegistered) {
      throw StateError('HID non enregistré.');
    }

    HidValidator.validateReportId(reportId);

    if (!state.grabbedReportIds.contains(reportId)) {
      throw StateError('Report HID $reportId non disponible.');
    }

    if (reportId == HidCommands.reportDesktop) {
      HidValidator.validateDesktopReport(report);
    } else if (reportId == HidCommands.reportKeyboard) {
      HidValidator.validateKeyboardReport(report);
    } else if (reportId == HidCommands.reportConsumer) {
      HidValidator.validateConsumerReport(report);
    }

    final payload = HidData.build(
      deviceId: deviceId,
      reportId: reportId,
      data: report,
    );

    await sender.send(HidCommands.deviceData, payload, reliable: true);
  }
}

