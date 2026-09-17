import 'commands/hid_feature.dart';

import 'hid_commands.dart';
import 'hid_sender.dart';
import 'hid_state.dart';
import 'hid_validator.dart';

class HidFeatureSender {
  HidFeatureSender({required this.sender, required this.state});

  final HidSender sender;
  final HidState state;

  static const int deviceId = 1;

  Future<void> sendFeature(int reportId, List<int> data) async {
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

    final payload = HidFeature.build(
      deviceId: deviceId,
      reportId: reportId,
      data: data,
    );

    await sender.send(HidCommands.deviceFeature, payload, reliable: true);
  }
}
