import '../../hid/freebox_keys.dart';
import '../../hid/hid_client.dart';

class TvChannelZapper {
  final HidClient player;

  const TvChannelZapper(this.player);

  Future<void> selectChannel(int channelNumber) async {
    final number = channelNumber.toString();

    for (final character in number.split('')) {
      final digit = int.tryParse(character);

      if (digit == null) {
        continue;
      }

      final key = _keyForDigit(digit);

      if (key == null) {
        continue;
      }

      await sendFreeboxKey(key, player);

      await Future.delayed(const Duration(milliseconds: 80));
    }

    await sendFreeboxKey(FreeboxKey.ok, player);
  }

  FreeboxKey? _keyForDigit(int digit) {
    const keys = <int, FreeboxKey>{
      0: FreeboxKey.key0,
      1: FreeboxKey.key1,
      2: FreeboxKey.key2,
      3: FreeboxKey.key3,
      4: FreeboxKey.key4,
      5: FreeboxKey.key5,
      6: FreeboxKey.key6,
      7: FreeboxKey.key7,
      8: FreeboxKey.key8,
      9: FreeboxKey.key9,
    };

    return keys[digit];
  }
}
