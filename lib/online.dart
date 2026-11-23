/// Offline stub — online returns later without breaking APK builds.
class OnlineService {
  static bool ready = false;
  static String playerId = 'local';
  static String displayName = 'Pilot';

  static Future<void> init() async {
    ready = false;
  }

  static Future<void> setName(String name) async {
    if (name.trim().isNotEmpty) {
      displayName = name.trim().substring(0, name.trim().length.clamp(0, 16));
    }
  }

  static Future<bool> submitScore({required int score, required int wave, required String mode}) async => false;

  static Future<List<Map<String, dynamic>>> topScores({String mode = 'classic', int limit = 15}) async => [];
}
