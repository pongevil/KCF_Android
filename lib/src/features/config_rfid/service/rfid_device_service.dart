import 'package:bs_mobile/src/core/rfid/urovo/urovo.dart';

/// Thin adapter over the Urovo RFID SDK for power get/set.
/// Presentation must not call [Urovo] directly.
class RfidDeviceService {
  Future<int?> getPower() => Urovo.getPower();

  Future<bool> setPower(int power) async {
    final result = await Urovo.setPower(power);
    return result != 'Error';
  }
}
