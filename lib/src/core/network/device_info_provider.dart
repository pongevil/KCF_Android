import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class DeviceInfoProvider {
  const DeviceInfoProvider();

  Future<String> getLocalIpAddress() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.first == ConnectivityResult.mobile ||
          result.first == ConnectivityResult.wifi) {
        for (final iface in await NetworkInterface.list()) {
          for (final addr in iface.addresses) {
            if (addr.type == InternetAddressType.IPv4) return addr.address;
          }
        }
      }
    } on PlatformException catch (_) {}
    return '';
  }

  Future<String> getModelDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      }
    } catch (_) {}
    return '';
  }
}
