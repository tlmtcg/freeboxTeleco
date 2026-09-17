import 'hid_commands.dart';

class HidState {
  bool _isRegistered = false;

  final Set<int> _grabbedReportIds = <int>{};

  bool get isRegistered => _isRegistered;

  bool get unicodeGrabbed =>
      _grabbedReportIds.contains(HidCommands.reportUnicode);

  bool get keyboardGrabbed =>
      _grabbedReportIds.contains(HidCommands.reportKeyboard);

  bool get consumerGrabbed =>
      _grabbedReportIds.contains(HidCommands.reportConsumer);

  bool get desktopGrabbed =>
      _grabbedReportIds.contains(HidCommands.reportDesktop);

  bool get isReady {
    return _isRegistered && keyboardGrabbed && consumerGrabbed;
  }

  Set<int> get grabbedReportIds => Set<int>.unmodifiable(_grabbedReportIds);

  void register() {
    _isRegistered = true;
  }

  void grabReport(int reportId) {
    _grabbedReportIds.add(reportId);
  }

  void releaseReport(int reportId) {
    _grabbedReportIds.remove(reportId);
  }

  void reset() {
    _isRegistered = false;
    _grabbedReportIds.clear();
  }
}
