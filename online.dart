import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Same project as web Pixel Orbit (publishable / anon key — safe in client).
const kSupabaseUrl = 'https://qdoqpuodighoozkjqqde.supabase.co';
const kSupabaseAnonKey = 'sb_publishable_RzgTves0OO2qgjhfY2afQw_03kYfK2x';

class OnlineService {
  static bool ready = false;
  static String playerId = '';
  static String displayName = 'Pilot';

  static Future<void> init() async {
    try {
      await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
      final p = await SharedPreferences.getInstance();
      playerId = p.getString('po_pid') ?? const Uuid().v4();
      displayName = p.getString('po_name') ?? 'Pilot${playerId.substring(0, 4)}';
      await p.setString('po_pid', playerId);
      await p.setString('po_name', displayName);
      ready = true;
    } catch (e) {
      ready = false;
      // ignore: avoid_print
      print('Supabase init failed: $e');
    }
  }

  static SupabaseClient? get client => ready ? Supabase.instance.client : null;

  static Future<void> setName(String name) async {
    displayName = name.trim().isEmpty ? displayName : name.trim().substring(0, name.trim().length.clamp(0, 16));
    final p = await SharedPreferences.getInstance();
    await p.setString('po_name', displayName);
  }

  static Future<bool> submitScore({
    required int score,
    required int wave,
    required String mode,
  }) async {
    final c = client;
    if (c == null || score <= 0) return false;
    try {
      await c.from('po_scores').insert({
        'player_id': playerId,
        'display_name': displayName,
        'score': score,
        'wave': wave,
        'mode': mode,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('submitScore: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> topScores({
    String mode = 'classic',
    int limit = 15,
  }) async {
    final c = client;
    if (c == null) return [];
    try {
      final rows = await c
          .from('po_scores')
          .select('display_name, score, wave, mode, created_at')
          .eq('mode', mode)
          .order('score', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      // ignore: avoid_print
      print('topScores: $e');
      return [];
    }
  }
}
