import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtil {
  static Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        // Retorna ex: "samsung SM-G991B (ID: a1b2c3d4e5)"
        return "${androidInfo.brand} ${androidInfo.model} (ID: ${androidInfo.id})";
        
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        
        // Retorna ex: "Apple iPhone 13 (ID: A1B2-C3D4...)"
        return "Apple ${iosInfo.name} (ID: ${iosInfo.identifierForVendor})";
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}