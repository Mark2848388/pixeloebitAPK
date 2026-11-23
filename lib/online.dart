import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Public client configuration only. Never put service_role/secret keys in the app.
const kSupabaseUrl = 'https://qdoqpuodighoozkjqqde.supabase.co';
const kSupabasePublishableKey = 'sb_publishable_RzgTves0OO2qgjhfY2afQw_03kYfK2x';

class OnlineService {
  static bool ready = false;
  static bool authenticated = false;
  static String playerId = '';
  static String pilotCode = '';
  static String avatarCode = 'a0';
  static String displayName = 'Pilot';
  static Timer? _cloudSaveTimer;
  static Map<String, dynamic>? _queuedSave;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    playerId = prefs.getString('po_pid') ?? const Uuid().v4();
    pilotCode = prefs.getString('po_code') ?? '';
    avatarCode = prefs.getString('po_avatar') ?? 'a0';
    displayName = prefs.getString('po_name') ?? 'Pilot${playerId.substring(0, 4)}';
    await prefs.setString('po_pid', playerId);
    await prefs.setString('po_name', displayName);
    try {
      await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabasePublishableKey);
      ready = true;
      final auth = Supabase.instance.client.auth;
      var user = auth.currentUser;
      if (user == null) {
        try {
          final session = await auth.signInAnonymously().timeout(const Duration(seconds: 6));
          user = session.user;
        } catch (e) {
          // Anonymous Auth may be disabled in project settings. Public score read/write
          // still works with the public key, but profile/friends/save APIs require auth.
          print('Anonymous auth unavailable: $e');
        }
      }
      if (user != null) {
        playerId = user.id;
        authenticated = true;
        await prefs.setString('po_pid', playerId);
        await _ensureProfile().timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      ready = false;
      authenticated = false;
      print('Supabase init failed: $e');
    }
  }

  static SupabaseClient? get client => ready ? Supabase.instance.client : null;
  static String? get authUserId => authenticated ? client?.auth.currentUser?.id : null;


  static String _makePilotCode(String uid) {
    final compact = uid.replaceAll('-', '').toUpperCase();
    return 'PO-${compact.substring(compact.length - 8)}';
  }


  static Future<void> _ensureProfile() async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return;
    try {
      final existing = await c.from('pilot_profiles').select('pilot_code,avatar').eq('user_id', uid).maybeSingle();
      if (existing != null) {
        pilotCode = existing['pilot_code']?.toString() ?? _makePilotCode(uid);
        avatarCode = existing['avatar']?.toString() ?? avatarCode;
      } else {
        // Never carry a cached code over to a different anonymous account.
        pilotCode = _makePilotCode(uid);
      }
      await c.from('pilot_profiles').upsert({
        'user_id': uid,
        'pilot_code': pilotCode,
        'display_name': displayName,
        'avatar': avatarCode,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('po_code', pilotCode);
      await prefs.setString('po_avatar', avatarCode);
    } catch (e) {
      print('Profile sync failed: $e');
    }
  }


  static Future<void> setAvatar(String code) async {
    avatarCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('po_avatar', code);
    final c = client;
    final uid = authUserId;
    if (c != null && uid != null) {
      try { await c.from('pilot_profiles').update({'avatar': code}).eq('user_id', uid); }
      catch (e) { print('avatar sync failed: $e'); }
    }
  }

  static Future<void> syncProfileLevel(int level) async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return;
    try {
      await c.from('pilot_profiles').update({'level': level.clamp(1, 100000), 'last_seen': DateTime.now().toUtc().toIso8601String()}).eq('user_id', uid);
    } catch (e) { print('profile level sync failed: $e'); }
  }


  static Future<void> setName(String name) async {
    final clean = name.trim();
    if (clean.isNotEmpty) displayName = clean.substring(0, clean.length > 16 ? 16 : clean.length);
    final p = await SharedPreferences.getInstance();
    await p.setString('po_name', displayName);
    final c = client;
    final uid = authUserId;
    if (c != null && uid != null) {
      try {
        await c.from('pilot_profiles').update({'display_name': displayName, 'last_seen': DateTime.now().toUtc().toIso8601String()}).eq('user_id', uid);
      } catch (e) { print('Name sync failed: $e'); }
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
    } catch (e) { print('submitScore: $e'); return false; }
  }


  static Future<List<Map<String, dynamic>>> topScores({String mode = 'classic', int limit = 20}) async {
    final c = client;
    if (c == null) return [];
    try {
      final rows = await c.from('po_scores').select('display_name, score, wave, mode, created_at').eq('mode', mode).order('score', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) { print('topScores: $e'); return []; }
  }


  static Future<Map<String, dynamic>?> findPilot(String code) async {
    final c = client;
    if (c == null || !authenticated) return null;
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;
    try {
      final row = await c.from('pilot_profiles').select('user_id,pilot_code,display_name,avatar,level').eq('pilot_code', clean).maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (e) { print('findPilot: $e'); return null; }
  }


  static Future<String> sendFriendRequest(String pilotCodeInput) async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return 'Нужна онлайн-авторизация (гостевой вход).';
    final target = await findPilot(pilotCodeInput);
    if (target == null) return 'Пилот не найден. Проверь код.';
    final targetId = target['user_id'] as String?;
    if (targetId == uid) return 'Нельзя добавить самого себя.';
    if (targetId == null) return 'Профиль не найден.';
    try {
      final sent = await c.from('friend_requests').select('id,status').eq('sender_id', uid).eq('receiver_id', targetId).limit(1);
      if (sent.isNotEmpty) {
        final status = sent.first['status'];
        return status == 'accepted' ? 'Вы уже друзья.' : 'Запрос уже отправлен.';
      }
      final received = await c.from('friend_requests').select('id,status').eq('sender_id', targetId).eq('receiver_id', uid).limit(1);
      if (received.isNotEmpty) return received.first['status'] == 'accepted' ? 'Вы уже друзья.' : 'Этот пилот уже отправил вам запрос. Откройте входящие.';
      await c.from('friend_requests').insert({'sender_id': uid, 'receiver_id': targetId, 'status': 'pending'});
      return 'Запрос отправлен пилоту ${target['display_name']}!';
    } catch (e) { print('sendFriendRequest: $e'); return 'Не удалось отправить запрос. Проверьте соединение.'; }
  }


  static Future<List<Map<String, dynamic>>> loadFriendRows() async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return [];
    try {
      final a = await c.from('friend_requests').select('id,sender_id,receiver_id,status,created_at').eq('sender_id', uid).order('created_at', ascending: false);
      final b = await c.from('friend_requests').select('id,sender_id,receiver_id,status,created_at').eq('receiver_id', uid).order('created_at', ascending: false);
      final all = <Map<String, dynamic>>[...List<Map<String, dynamic>>.from(a), ...List<Map<String, dynamic>>.from(b)];
      final ids = all.map((r) => r['sender_id'] == uid ? r['receiver_id'] as String : r['sender_id'] as String).toSet().toList();
      final profiles = ids.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(await c.from('pilot_profiles').select('user_id,pilot_code,display_name,avatar,level').inFilter('user_id', ids));
      final byId = {for (final profile in profiles) profile['user_id'] as String: profile};
      return all.map((r) {
        final otherId = r['sender_id'] == uid ? r['receiver_id'] : r['sender_id'];
        return {...r, 'other_user_id': otherId, 'other': byId[otherId] ?? <String, dynamic>{}, 'outgoing': r['sender_id'] == uid};
      }).toList();
    } catch (e) { print('loadFriendRows: $e'); return []; }
  }


  static Future<bool> respondFriendRequest(int id, bool accept) async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return false;
    try {
      await c.from('friend_requests').update({'status': accept ? 'accepted' : 'declined', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id).eq('receiver_id', uid).eq('status', 'pending');
      return true;
    } catch (e) { print('respondFriendRequest: $e'); return false; }
  }


  static Future<bool> removeFriend(int id) async {
    final c = client;
    if (c == null || authUserId == null) return false;
    try {
      await c.from('friend_requests').delete().eq('id', id).eq('status', 'accepted');
      return true;
    } catch (e) { print('removeFriend: $e'); return false; }
  }


  static Future<Map<String, dynamic>?> loadCloudSave() async {
    final c = client;
    final uid = authUserId;
    if (c == null || uid == null) return null;
    try {
      final row = await c.from('pixelorbit_game_saves').select('save_data,updated_at').eq('user_id', uid).maybeSingle().timeout(const Duration(seconds: 3));
      if (row == null) return null;
      return {'data': Map<String, dynamic>.from(row['save_data'] as Map), 'updated_at': row['updated_at']};
    } catch (e) { print('loadCloudSave: $e'); return null; }
  }


  static void queueCloudSave(Map<String, dynamic> data) {
    if (!authenticated || client == null) return;
    _queuedSave = Map<String, dynamic>.from(data);
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = Timer(const Duration(seconds: 2), () async {
      final payload = _queuedSave;
      final c = client;
      final uid = authUserId;
      if (payload == null || c == null || uid == null) return;
      try {
        await c.from('pixelorbit_game_saves').upsert({'user_id': uid, 'save_data': payload, 'client_updated_at': DateTime.now().toUtc().toIso8601String(), 'updated_at': DateTime.now().toUtc().toIso8601String()}, onConflict: 'user_id');
      } catch (e) { print('cloud save failed: $e'); }
    });
  }


  static Future<List<Map<String, dynamic>>> loadActiveEvents() async {
    final c = client;
    if (c == null || !authenticated) return [];
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await c.from('pixel_game_events').select('title,description,starts_at,ends_at,reward_coins,reward_parts').eq('active', true).lte('starts_at', now).gte('ends_at', now).order('starts_at').timeout(const Duration(seconds: 4));
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) { print('loadActiveEvents: $e'); return []; }
  }


  static Future<void> flushCloudSave() async {
    _cloudSaveTimer?.cancel();
    final payload = _queuedSave;
    final c = client;
    final uid = authUserId;
    if (payload == null || c == null || uid == null) return;
    try {
      await c.from('pixelorbit_game_saves').upsert({'user_id': uid, 'save_data': payload, 'client_updated_at': DateTime.now().toUtc().toIso8601String(), 'updated_at': DateTime.now().toUtc().toIso8601String()}, onConflict: 'user_id');
    } catch (e) { print('cloud save flush failed: $e'); }
  }
}
