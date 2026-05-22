/// Centralized API configuration.
/// Change [baseUrl] here to switch between local dev and production.
class ApiConfig {
  // For physical device via USB: use 127.0.0.1 (with adb reverse tcp:5000 tcp:5000)
  // For Android emulator: use 10.0.2.2
  // For physical device on same WiFi: use your PC's local IP (e.g. 192.168.31.159)
  static const String baseUrl = 'http://10.151.179.100:5000';
}
