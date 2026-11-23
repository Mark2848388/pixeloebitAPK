import 'package:flutter_test/flutter_test.dart';
import 'package:pixelorbit/progress.dart';

void main() {
  test('progress cloud JSON round-trips player currencies and upgrades', () {
    final p = PlayerProgress(
      coins: 321,
      gems: 12,
      scrap: 44,
      seasonXp: 987,
      seasonLevel: 8,
      highScore: 12000,
      endlessHigh: 4000,
      arenaWins: 3,
      gamesPlayed: 25,
      campaignWorld: 4,
      freeChests: 2,
      baseLevel: 5,
      premium: true,
      activeHero: 'nova',
      playerName: 'Pilot Test',
      bio: 'test profile',
      ownedHeroes: {'rex', 'nova'},
      ownedSkins: {'default', 'blue'},
      upgradeLv: {'dmg': 3, 'rate': 2},
      friends: ['Local Friend'],
      notifications: ['Hello'],
    );
    final restored = PlayerProgress.fromJson(p.toJson());
    expect(restored.coins, 321);
    expect(restored.gems, 12);
    expect(restored.scrap, 44);
    expect(restored.seasonLevel, 8);
    expect(restored.activeHero, 'nova');
    expect(restored.ownedHeroes, {'rex', 'nova'});
    expect(restored.ownedSkins, {'default', 'blue'});
    expect(restored.upgradeLv['dmg'], 3);
    expect(restored.friends, ['Local Friend']);
    expect(restored.notifications, ['Hello']);
  });
}
