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
  WorldInfo(1, 'Орбита-1', 'Тренировка', 0xFF4A7AFF, 3, 40),
  WorldInfo(2, 'Алый Пояс', 'Рой дронов', 0xFFFF4A6A, 4, 55),
  WorldInfo(3, 'Изумруд', 'Стражи', 0xFF40C070, 4, 70),
  WorldInfo(4, 'Неон', 'Рейдеры', 0xFF40FFC0, 5, 90),
  WorldInfo(5, 'Шпиль', 'Огонь', 0xFFFFB040, 5, 110),
  WorldInfo(6, 'Тень', 'Охотники', 0xFF9B4DFF, 6, 130),
  WorldInfo(7, 'Крио', 'Лёд', 0xFF80D0FF, 6, 150),
  WorldInfo(8, 'Трон', 'Элита', 0xFFFF3A4A, 7, 180),
  WorldInfo(9, 'Край', 'Финал+', 0xFFFFD34A, 7, 210),
  WorldInfo(10, 'Ядро', '3 фазы', 0xFFFF80D0, 8, 280),
];

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
  HeroInfo(id: 'rex', name: 'РЕКС', role: 'Капитан', desc: 'Баланс. Залп ракет.', ultName: 'ЗАЛП', dashName: 'РЫВОК', unlockWorld: 0, color: 0xFF4A7AFF),
  HeroInfo(id: 'nova', name: 'НОВА', role: 'Стрелок', desc: 'Веер огня.', ultName: 'ВЕЕР', dashName: 'МИГ', unlockWorld: 2, color: 0xFFFF60C0, fireRateMul: 0.65, damageMul: 0.85, weapon: 'spread'),
  HeroInfo(id: 'bolt', name: 'БОЛТ', role: 'Гонщик', desc: 'Скорость.', ultName: 'НИТРО', dashName: 'БЛИЦ', unlockWorld: 3, color: 0xFFFFB020, speedMul: 1.35),
  HeroInfo(id: 'aegis', name: 'ЭГИДА', role: 'Танк', desc: '+HP, щит.', ultName: 'БАРЬЕР', dashName: 'ТОЛЧОК', unlockWorld: 5, color: 0xFF30C070, bonusLives: 1, damageMul: 0.9, weapon: 'beam'),
  HeroInfo(id: 'shadow', name: 'ТЕНЬ', role: 'Ассасин', desc: 'Крит урон.', ultName: 'ЗАТМЕНИЕ', dashName: 'ФАЗА', unlockWorld: 7, color: 0xFF8A40E0, fireRateMul: 1.15, damageMul: 1.55, weapon: 'rail'),
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
