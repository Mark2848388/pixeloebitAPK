class WorldInfo {
  final int id;
  final String name;
  final String blurb;
  final int color;
  final int wavesToClear;
  final int bossHp;
  const WorldInfo(this.id, this.name, this.blurb, this.color, this.wavesToClear, this.bossHp);
}

const worlds = <WorldInfo>[
  // wavesToClear unused for campaign structure; each world has 10 levels
  WorldInfo(1, 'Орбита-1', '10 уровней', 0xFF4A7AFF, 10, 36),
  WorldInfo(2, 'Алый Пояс', '10 уровней', 0xFFFF4A6A, 10, 48),
  WorldInfo(3, 'Изумруд', '10 уровней', 0xFF40C070, 10, 58),
  WorldInfo(4, 'Неон', '10 уровней', 0xFF40FFC0, 10, 72),
  WorldInfo(5, 'Шпиль', '10 уровней', 0xFFFFB040, 10, 88),
  WorldInfo(6, 'Тень', '10 уровней', 0xFF9B4DFF, 10, 100),
  WorldInfo(7, 'Крио', '10 уровней', 0xFF80D0FF, 10, 115),
  WorldInfo(8, 'Трон', '10 уровней', 0xFFFF3A4A, 10, 130),
  WorldInfo(9, 'Край', '10 уровней', 0xFFFFD34A, 10, 150),
  WorldInfo(10, 'Ядро', '10 уровней', 0xFFFF80D0, 10, 180),
];

/// campaign progress: levels cleared 0..100 (10 worlds * 10 levels)
int campaignWorldOf(int stagesCleared) => (stagesCleared ~/ 10) + 1;
int campaignLevelOf(int stagesCleared) => (stagesCleared % 10) + 1;


class HeroInfo {
  final String id, name, role, desc, ultName, dashName, weapon;
  final int unlockWorld, color, bonusLives;
  final double fireRateMul, damageMul, speedMul;
  const HeroInfo({
    required this.id, required this.name, required this.role, required this.desc,
    required this.ultName, required this.dashName, required this.unlockWorld, required this.color,
    this.fireRateMul = 1, this.damageMul = 1, this.speedMul = 1, this.bonusLives = 0, this.weapon = 'pulse',
  });
}

const heroes = <HeroInfo>[
  HeroInfo(id: 'rex', name: 'РЕКС', role: 'Капитан', desc: 'Баланс.', ultName: 'ЗАЛП', dashName: 'РЫВОК', unlockWorld: 0, color: 0xFF4A7AFF),
  HeroInfo(id: 'nova', name: 'НОВА', role: 'Стрелок', desc: 'Веер.', ultName: 'ВЕЕР', dashName: 'МИГ', unlockWorld: 2, color: 0xFFFF60C0, fireRateMul: 0.65, damageMul: 0.85, weapon: 'spread'),
  HeroInfo(id: 'bolt', name: 'БОЛТ', role: 'Гонщик', desc: 'Скорость.', ultName: 'НИТРО', dashName: 'БЛИЦ', unlockWorld: 3, color: 0xFFFFB020, speedMul: 1.35),
  HeroInfo(id: 'aegis', name: 'ЭГИДА', role: 'Танк', desc: '+HP.', ultName: 'БАРЬЕР', dashName: 'ТОЛЧОК', unlockWorld: 5, color: 0xFF30C070, bonusLives: 1, damageMul: 0.9, weapon: 'beam'),
  HeroInfo(id: 'shadow', name: 'ТЕНЬ', role: 'Ассасин', desc: 'Крит.', ultName: 'ЗАТМЕНИЕ', dashName: 'ФАЗА', unlockWorld: 7, color: 0xFF8A40E0, fireRateMul: 1.15, damageMul: 1.55, weapon: 'rail'),
];

class UpgradeDef {
  final String id, name;
  final int maxLevel, baseCost;
  const UpgradeDef(this.id, this.name, this.maxLevel, this.baseCost);
}

const upgrades = [
  UpgradeDef('dmg', 'Урон', 10, 80),
  UpgradeDef('rate', 'Скорострельность', 10, 80),
  UpgradeDef('dash', 'Рывок КД', 5, 120),
  UpgradeDef('ult', 'Ульта КД', 5, 150),
  UpgradeDef('hull', 'Корпус', 5, 100),
  UpgradeDef('regen', 'Регенерация', 5, 140),
];

/// Collectible pixel mini-people (gacha / season)
enum CharRarity { common, rare, epic, legendary }

class PixelChar {
  final String id, name;
  final CharRarity rarity;
  final String blurb;
  final int color;
  /// simple face code for painter: 0 default, 1 glasses (D-56)
  final int style;
  const PixelChar(this.id, this.name, this.rarity, this.blurb, this.color, {this.style = 0});
}

const pixelChars = <PixelChar>[
  PixelChar('c_pio', 'Пио', CharRarity.common, 'Новичок дока', 0xFF8A96B0),
  PixelChar('c_mira', 'Мира', CharRarity.common, 'Скаут', 0xFF80D0FF),
  PixelChar('c_rok', 'Рок', CharRarity.common, 'Механик', 0xFFFFB040),
  PixelChar('c_nyx', 'Никс', CharRarity.rare, 'Теневой связной', 0xFF9B4DFF),
  PixelChar('c_luna', 'Луна', CharRarity.rare, 'Навигатор', 0xFFFF80D0),
  PixelChar('c_vex', 'Векс', CharRarity.rare, 'Взрывник', 0xFFFF4A6A),
  PixelChar('c_orion', 'Орион', CharRarity.epic, 'Капитан эсминца', 0xFF5B8CFF),
  PixelChar('c_kira', 'Кира', CharRarity.epic, 'Ас', 0xFF40FFA0),
  PixelChar('c_d56', 'Д-56', CharRarity.legendary, 'Паренёк в очках. Сезон 40.', 0xFFE8EEFF, style: 1),
];

String rarityName(CharRarity r) {
  switch (r) {
    case CharRarity.common: return 'Обычный';
    case CharRarity.rare: return 'Редкий';
    case CharRarity.epic: return 'Эпический';
    case CharRarity.legendary: return 'Легенда';
  }
}

int rarityColor(CharRarity r) {
  switch (r) {
    case CharRarity.common: return 0xFF8A96B0;
    case CharRarity.rare: return 0xFF5B8CFF;
    case CharRarity.epic: return 0xFF9B4DFF;
    case CharRarity.legendary: return 0xFFFFD34A;
  }
}

class BuildingDef {
  final String id, name;
  final int cost, coinsPerHour, color;
  final String desc;
  const BuildingDef(this.id, this.name, this.cost, this.coinsPerHour, this.color, this.desc);
}

const buildings = <BuildingDef>[
  BuildingDef('gen', 'Генератор', 100, 12, 0xFF5B8CFF, '+монеты/час'),
  BuildingDef('mine', 'Шахта', 180, 22, 0xFFFFB040, 'Скрап и монеты'),
  BuildingDef('lab', 'Лаба', 250, 8, 0xFF9B4DFF, 'Бонус XP сезона'),
  BuildingDef('turret', 'Турель', 200, 5, 0xFFFF4A6A, 'Бонус к урону в бою'),
  BuildingDef('pad', 'Площадка', 150, 10, 0xFF40C070, 'Бонус к базе'),
];

class CompanionInfo {
  final String id, name, desc;
  final int cost, color;
  const CompanionInfo(this.id, this.name, this.desc, this.cost, this.color);
}

const companions = <CompanionInfo>[
  CompanionInfo('drone', 'ДРОН', 'Стреляет с тобой', 120, 0xFF40FFA0),
  CompanionInfo('shieldbot', 'ЩИТ-БОТ', 'Пассив', 200, 0xFF80D0FF),
  CompanionInfo('miner', 'ШАХТЁР', 'Лут+', 180, 0xFFFFD34A),
];

/// Season pass: 40 levels. Level 40 = D-56
class SeasonReward {
  final int level;
  final String title;
  final int coins, gems, scrap;
  final String? charId;
  const SeasonReward(this.level, this.title, {this.coins = 0, this.gems = 0, this.scrap = 0, this.charId});
}

List<SeasonReward> buildSeasonTrack() {
  final list = <SeasonReward>[];
  for (var lv = 1; lv <= 40; lv++) {
    if (lv == 40) {
      list.add(const SeasonReward(40, 'Д-56', coins: 500, gems: 20, charId: 'c_d56'));
    } else if (lv % 10 == 0) {
      list.add(SeasonReward(lv, 'Набор $lv', coins: 200 + lv * 5, gems: 5, scrap: 30));
    } else if (lv % 5 == 0) {
      list.add(SeasonReward(lv, 'Ящик $lv', coins: 80 + lv * 3, scrap: 15, gems: 1));
    } else {
      list.add(SeasonReward(lv, 'Награда $lv', coins: 30 + lv * 2, scrap: 4));
    }
  }
  return list;
}

final seasonTrack = buildSeasonTrack();
