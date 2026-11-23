/// Campaign worlds, heroes, chests — static content for Pixel Orbit.

class WorldInfo {
  final int id;
  final String name;
  final String blurb;
  final int color;
  final int wavesToClear; // classic waves needed to beat world
  final int bossHp;
  const WorldInfo(this.id, this.name, this.blurb, this.color, this.wavesToClear, this.bossHp);
}

const worlds = <WorldInfo>[
  WorldInfo(1, 'Орбита-1', 'Тренировочный сектор', 0xFF4A7AFF, 3, 12),
  WorldInfo(2, 'Алый Пояс', 'Рой алых дронов', 0xFFFF4A6A, 4, 18),
  WorldInfo(3, 'Изумрудный Туман', 'Ядовитые стражи', 0xFF40C070, 4, 22),
  WorldInfo(4, 'Пустошь Неон', 'Скоростные рейдеры', 0xFF40FFC0, 5, 28),
  WorldInfo(5, 'Солнечный Шпиль', 'Огненные патрули', 0xFFFFB040, 5, 34),
  WorldInfo(6, 'Теневой Риф', 'Невидимые охотники', 0xFF9B4DFF, 6, 40),
  WorldInfo(7, 'Крио-Дыра', 'Ледяные тараны', 0xFF80D0FF, 6, 48),
  WorldInfo(8, 'Багровый Трон', 'Элита империи', 0xFFFF3A4A, 7, 56),
  WorldInfo(9, 'Звёздный Край', 'Перед финалом', 0xFFFFD34A, 7, 64),
  WorldInfo(10, 'Ядро Орбиты', 'Финальный босс', 0xFFFF80D0, 8, 80),
];

class HeroInfo {
  final String id;
  final String name;
  final String role;
  final String desc;
  final int unlockWorld; // 0 = start
  final int color;
  final double fireRateMul; // <1 = faster
  final double damageMul;
  final double speedMul;
  const HeroInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.desc,
    required this.unlockWorld,
    required this.color,
    this.fireRateMul = 1,
    this.damageMul = 1,
    this.speedMul = 1,
  });
}

const heroes = <HeroInfo>[
  HeroInfo(
    id: 'rex',
    name: 'Рекс',
    role: 'Пилот',
    desc: 'Стандартный огонь. Надёжный старт.',
    unlockWorld: 0,
    color: 0xFF4A7AFF,
  ),
  HeroInfo(
    id: 'nova',
    name: 'Нова',
    role: 'Стрелок',
    desc: 'Быстрая стрельба, чуть слабее урон.',
    unlockWorld: 2,
    color: 0xFFFF80D0,
    fireRateMul: 0.7,
    damageMul: 0.85,
  ),
  HeroInfo(
    id: 'bolt',
    name: 'Болт',
    role: 'Гонщик',
    desc: 'Выше скорость корабля.',
    unlockWorld: 4,
    color: 0xFFFFB040,
    speedMul: 1.35,
  ),
  HeroInfo(
    id: 'aegis',
    name: 'Эгида',
    role: 'Танк',
    desc: '+1 жизнь в начале боя.',
    unlockWorld: 6,
    color: 0xFF40C070,
  ),
  HeroInfo(
    id: 'shadow',
    name: 'Тень',
    role: 'Ассасин',
    desc: 'Сильный урон, реже выстрелы.',
    unlockWorld: 8,
    color: 0xFF9B4DFF,
    fireRateMul: 1.25,
    damageMul: 1.6,
  ),
];

class ChestDef {
  final String id;
  final String name;
  final int priceCoins;
  final int minCoins;
  final int maxCoins;
  final int gemChance; // 0-100
  final int skinChance;
  const ChestDef({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.minCoins,
    required this.maxCoins,
    this.gemChance = 10,
    this.skinChance = 5,
  });
}

const chests = <ChestDef>[
  ChestDef(id: 'wood', name: 'Деревянный', priceCoins: 80, minCoins: 40, maxCoins: 120, gemChance: 8, skinChance: 2),
  ChestDef(id: 'iron', name: 'Железный', priceCoins: 200, minCoins: 100, maxCoins: 280, gemChance: 18, skinChance: 6),
  ChestDef(id: 'gold', name: 'Золотой', priceCoins: 450, minCoins: 220, maxCoins: 500, gemChance: 35, skinChance: 15),
  ChestDef(id: 'legend', name: 'Легендарный', priceCoins: 900, minCoins: 400, maxCoins: 900, gemChance: 55, skinChance: 30),
];
