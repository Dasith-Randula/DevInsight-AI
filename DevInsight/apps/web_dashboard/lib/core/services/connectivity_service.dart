import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  const ConnectivityService();

  Future<bool> hasConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();

      // This reports available network interfaces, not guaranteed service reachability.
      // That is preferable here to a browser HTTP probe that can fail because of CORS.
      return results.isEmpty ||
          !results.every((result) => result == ConnectivityResult.none);
    } catch (_) {
      // A checker failure must not prevent the user from entering DevInsight.
      return true;
    }
  }
}
