import 'hid_commands.dart';

class HidValidator {
  static void validateReportId(int reportId) {
    if (!HidCommands.isValidReportId(reportId)) {
      throw ArgumentError('Report HID invalide : $reportId');
    }
  }

  static void validateReportAvailable(Set<int> grabbedReportIds, int reportId) {
    validateReportId(reportId);

    if (!grabbedReportIds.contains(reportId)) {
      throw StateError('Report HID $reportId non disponible.');
    }
  }

  static void validateKeyboardReport(List<int> report) {
    if (report.length != 2) {
      throw ArgumentError(
        'Un report Keyboard HID doit contenir exactement 2 octets.',
      );
    }
  }

  static void validateConsumerReport(List<int> report) {
    if (report.length != 2) {
      throw ArgumentError(
        'Un report Consumer HID doit contenir exactement 2 octets.',
      );
    }
  }

  static void validateDesktopReport(List<int> report) {
    if (report.length != 1) {
      throw ArgumentError(
        'Un report Desktop HID doit contenir exactement 1 octet.',
      );
    }
  }
}
