import '../hid_descriptor.dart';

/// Construction de la commande HID DEVICE_NEW.
///
/// Le payload complet est construit par HidDescriptor afin de conserver
/// exactement le format déjà validé avec le Player Freebox.
abstract final class HidDeviceNew {
  static List<int> build({required int deviceId, required String deviceName}) {
    return HidDescriptor.buildDeviceNewPayload(
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }
}
