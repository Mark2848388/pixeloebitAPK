import 'package:audioplayers/audioplayers.dart';

/// Lightweight original game SFX pool; avoids awaiting audio in the game tick.
class SfxAudio {
  static bool enabled = true;
  static final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  static int _next = 0;
  static void playShot() => _play('music/laser.wav', volume: .18);
  static void playExplosion() => _play('music/boom.wav', volume: .35);
  static void _play(String asset, {required double volume}) {
    if (!enabled) return;
    final player = _players[_next++ % _players.length];
    player.stop().then((_) => player.play(AssetSource(asset), volume: volume)).catchError((_) {});
  }
}
