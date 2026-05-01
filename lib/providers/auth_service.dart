import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return true; // If not supported, let it pass (or handle otherwise)

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to view your locked note',
      );
    } catch (e) {
      return false;
    }
  }
}
