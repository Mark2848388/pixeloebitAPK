import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSupabaseUrl = 'https://qdoqpuodighoozkjqqde.supabase.co';
const kSupabaseAnonKey = 'sb_publishable_RzgTves0OO2qgjhfY2afQw_03kYfK2x';

class OnlineService {
  static bool ready = false;
  static String playerId = '';
  static String displayName = 'Pilot';
  static int arenaRating = 1000;

  static Future<void> init() async {
    try {
      await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
      final p = await SharedPreferences.getInstance();
      playerId = p.getString('po_pid') ?? const Uuid().v4();
      displayName = p.getString('po_name') ?? 'Pilot${playerId.substring(0, 4)}';
      arenaRating = p.getInt('po_rating') ?? 1000;
      await p.setString('po_pid', playerId);
      await p.setString('po_name', displayName);
      ready = true;
      await upsertProfile();
    } catch (e) {
      ready = false;
      print('Supabase init failed: $e');
    }
  }

  static SupabaseClient? get client => ready ? Supabase.instance.client : null;

  static Future<void> setName(String name) async {
    displayName = name.trim().isEmpty ? displayName : name.trim().substring(0, name.trim().length.clamp(0, 16));
    final p = await SharedPreferences.getInstance();
    await p.setString('po_name', displayName);
    await upsertProfile();
  }

  static Future<void> upsertProfile({int? seasonLevel}) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('po_profiles').upsert({
        'player_id': playerId,
        'display_name': displayName,
        'arena_rating': arenaRating,
        'season_level': seasonLevel ?? 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('upsertProfile: $e');
    }
  }

  static Future<bool> submitScore({required int score, required int wave, required String mode}) async {
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
      print('submitScore: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> topScores({String mode = 'classic', int limit = 15}) async {
    final c = client;
    if (c == null) return [];
    try {
      final rows = await c.from('po_scores').select('display_name, score, wave, mode, created_at').eq('mode', mode).order('score', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> arenaLeaderboard({int limit = 30}) async {
    final c = client;
    if (c == null) return [];
    try {
      final rows = await c.from('po_profiles').select('player_id, display_name, arena_rating, arena_wins, arena_losses').order('arena_rating', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('arenaLeaderboard: $e');
      return [];
    }
  }

  static Future<void> reportArenaResult({required bool win, required int opponentRating}) async {
    // simple Elo-ish
    final expected = 1 / (1 + math.pow(10, (opponentRating - arenaRating) / 400));
    final score = win ? 1.0 : 0.0;
    final delta = (32 * (score - expected)).round();
    arenaRating = (arenaRating + delta).clamp(0, 5000);
    final p = await SharedPreferences.getInstance();
    await p.setInt('po_rating', arenaRating);
    final c = client;
    if (c == null) return;
    try {
      final row = await c.from('po_profiles').select('arena_wins, arena_losses').eq('player_id', playerId).maybeSingle();
      var wins = (row?['arena_wins'] as int?) ?? 0;
      var losses = (row?['arena_losses'] as int?) ?? 0;
      if (win) {
        wins++;
      } else {
        losses++;
      }
      await c.from('po_profiles').upsert({
        'player_id': playerId,
        'display_name': displayName,
        'arena_rating': arenaRating,
        'arena_wins': wins,
        'arena_losses': losses,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('reportArena: $e');
    }
  }

  static double pow10(double x) => (1.0 * 10).powApprox(x);

  static Future<List<Map<String, dynamic>>> listFriends() async {
    final c = client;
    if (c == null) return [];
    try {
      final rows = await c.from('po_friends').select('friend_id, friend_name, created_at').eq('player_id', playerId);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addFriendByName(String name) async {
    final c = client;
    if (c == null) return false;
    final n = name.trim();
    if (n.isEmpty) return false;
    try {
      final rows = await c.from('po_profiles').select('player_id, display_name').eq('display_name', n).limit(1);
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty) return false;
      final fid = list.first['player_id'] as String;
      if (fid == playerId) return false;
      await c.from('po_friends').upsert({
        'player_id': playerId,
        'friend_id': fid,
        'friend_name': list.first['display_name'],
      });
      return true;
    } catch (e) {
      print('addFriend: $e');
      return false;
    }
  }

  static Future<void> createDuel({required String opponentId, required String opponentName}) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('po_duels').insert({
        'challenger_id': playerId,
        'challenger_name': displayName,
        'opponent_id': opponentId,
        'opponent_name': opponentName,
        'status': 'pending',
      });
    } catch (e) {
      print('createDuel: $e');
    }
  }
}

