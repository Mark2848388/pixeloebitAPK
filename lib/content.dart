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
  WorldInfo(1, 'Орбита-1', 'Тренировочный сектор', 0xFF4A7AFF, 3, 40),
  WorldInfo(2, 'Алый Пояс', 'Рой алых дронов', 0xFFFF4A6A, 4, 55),
  WorldInfo(3, 'Изумрудный Туман', 'Ядовитые стражи', 0xFF40C070, 4, 70),
  WorldInfo(4, 'Пустошь Неон', 'Скоростные рейдеры', 0xFF40FFC0, 5, 90),
  WorldInfo(5, 'Солнечный Шпиль', 'Огненные патрули', 0xFFFFB040, 5, 110),
  WorldInfo(6, 'Теневой Риф', 'Невидимые охотники', 0xFF9B4DFF, 6, 130),
  WorldInfo(7, 'Крио-Дыра', 'Ледяные тараны', 0xFF80D0FF, 6, 150),
  WorldInfo(8, 'Багровый Трон', 'Элита империи', 0xFFFF3A4A, 7, 180),
  WorldInfo(9, 'Звёздный Край', 'Перед финалом', 0xFFFFD34A, 7, 210),
  WorldInfo(10, 'Ядро Орбиты', 'Трёхфазный босс', 0xFFFF80D0, 8, 280),
];

class HeroInfo {
  final String id;
  final String name;
  final String role;
  final String desc;
  final String ultName;
  final String dashName;
  final int unlockWorld;
  final int color;
  final double fireRateMul;
  final double damageMul;
  final double speedMul;
  final int bonusLives;
  final String weapon; // pulse | beam | spread | rail
  const HeroInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.desc,
    required this.ultName,
    required this.dashName,
    required this.unlockWorld,
    required this.color,
    this.fireRateMul = 1,
    this.damageMul = 1,
    this.speedMul = 1,
    this.bonusLives = 0,
    this.weapon = 'pulse',
  });
}

const heroes = <HeroInfo>[
  HeroInfo(
    id: 'rex',
    name: 'РЕКС',
    role: 'Капитан',
    desc: 'Сбалансированный огонь. Ульта: залп ракет.',
    ultName: 'ЗАЛП',
    dashName: 'РЫВОК',
    unlockWorld: 0,
    color: 0xFF4A7AFF,
    weapon: 'pulse',
  ),
  HeroInfo(
    id: 'nova',
    name: 'НОВА',
    role: 'Стрелок',
    desc: 'Быстрый огонь. Ульта: веер лазеров.',
    ultName: 'ВЕЕР',
    dashName: 'МИГАЛКА',
    unlockWorld: 2,
    color: 0xFFFF60C0,
    fireRateMul: 0.65,
    damageMul: 0.8,
    weapon: 'spread',
  ),
  HeroInfo(
    id: 'bolt',
    name: 'БОЛТ',
    role: 'Гонщик',
    desc: 'Скорость и рывок. Ульта: ускорение + щит.',
    ultName: 'НИТРО',
    dashName: 'БЛИЦ',
    unlockWorld: 3,
    color: 0xFFFFB020,
    speedMul: 1.4,
    weapon: 'pulse',
  ),
  HeroInfo(
    id: 'aegis',
    name: 'ЭГИДА',
    role: 'Танк',
    desc: '+жизнь. Ульта: щит на 4 сек.',
    ultName: 'БАРЬЕР',
    dashName: 'ТОЛЧОК',
    unlockWorld: 5,
    color: 0xFF30C070,
    bonusLives: 1,
    damageMul: 0.9,
    weapon: 'beam',
  ),
  HeroInfo(
    id: 'shadow',
    name: 'ТЕНЬ',
    role: 'Ассасин',
    desc: 'Сильный урон. Ульта: невидимость + крит.',
    ultName: 'ЗАТМЕНИЕ',
    dashName: 'ФАЗОВЫЙ',
    unlockWorld: 7,
    color: 0xFF8A40E0,
    fireRateMul: 1.15,
    damageMul: 1.55,
    weapon: 'rail',
  ),
];

class WeaponUpgrade {
  final String id;
  final String name;
  final int maxLevel;
  final int baseCost;
  const WeaponUpgrade(this.id, this.name, this.maxLevel, this.baseCost);
}

const upgrades = <WeaponUpgrade>[
  WeaponUpgrade('dmg', 'Урон', 10, 80),
  WeaponUpgrade('rate', 'Скорострельность', 10, 80),
  WeaponUpgrade('dash', 'Рывок КД', 5, 120),
  WeaponUpgrade('ult', 'Ульта КД', 5, 150),
  WeaponUpgrade('hull', 'Корпус', 5, 100),
];

class GameEvent {
  final String id;
  final String title;
  final String desc;
  final String mode; // classic | endless | arena
  final double rewardMul;
  const GameEvent(this.id, this.title, this.desc, this.mode, this.rewardMul);
}

const events = <GameEvent>[
  GameEvent('meteor', 'МЕТЕОРНЫЙ ДОЖДЬ', 'x1.5 монет в классике', 'classic', 1.5),
  GameEvent('arena_cup', 'КУБОК АРЕНЫ', 'Дуэли дают больше XP', 'arena', 1.4),
  GameEvent('endless_night', 'НОЧЬ БЕЗ КОНЦА', 'Endless x2 очков', 'endless', 2.0),
];
