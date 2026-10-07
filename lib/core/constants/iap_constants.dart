class IapConstants {
  IapConstants._();

  static const String productPrefix = 'tf';

  static const String remoteConfigUrl = 'https://api2.blwsmartware.net/N294.json';

  static const Duration configTimeout = Duration(seconds: 10);

  static const List<String> coinPackIds = [
    'tf_pack_1',
    'tf_pack_2',
    'tf_pack_3',
    'tf_pack_4',
    'tf_pack_5',
    'tf_pack_6',
    'tf_pack_7',
    'tf_pack_8',
    'tf_pack_9',
    'tf_pack_10',
  ];

  static const String removeAdsProductId = 'tf_remove_ads';
  static const String proProductId = 'tf_pro';

  static List<String> get allProductIds => [...coinPackIds, removeAdsProductId, proProductId];

  static const List<int> coinPackAmounts = [
    50, 100, 200, 350, 500, 750, 1000, 1500, 2200, 3000,
  ];

  static int coinsForProduct(String productId) {
    final index = coinPackIds.indexOf(productId);
    if (index < 0) return 0;
    return coinPackAmounts[index];
  }

  static bool isRemoveAdsProduct(String productId) => productId == removeAdsProductId;
  static bool isProProduct(String productId) => productId == proProductId;

  static const int dailyLoginReward = 10;
  static const int luckyDropReward = 2;
  static const int testStartReward = 4;
  static const int testCompleteReward = 8;
  static const int accuracyReward = 3;
  static const int maxDayRewards = 8;
  static const int freeArchiveLimit = 8;
  static const int proArchiveLimit = 99;

  static const int firstPurchaseBonusPercent = 50;
  static const int weeklyDealBonusPercent = 30;
  static const int bestValuePackIndex = 4;

  static const List<(int, int)> luckyPrizes = [
    (5, 35),
    (10, 28),
    (15, 18),
    (25, 12),
    (50, 5),
    (100, 2),
  ];

  static int weeklyHotDealPackIndex() {
    final week = DateTime.now().difference(DateTime(DateTime.now().year)).inDays ~/ 7;
    return week % coinPackIds.length;
  }

  static int bonusCoinsForPack(int packIndex, {required bool isFirstPurchase, required bool isHotDeal}) {
    final base = packIndex >= 0 && packIndex < coinPackAmounts.length ? coinPackAmounts[packIndex] : 0;
    var bonus = 0;
    if (isFirstPurchase) bonus += (base * firstPurchaseBonusPercent / 100).round();
    if (isHotDeal) bonus += (base * weeklyDealBonusPercent / 100).round();
    return bonus;
  }

  static int totalCoinsForPurchase(String productId, {required bool isFirstPurchase}) {
    final index = coinPackIds.indexOf(productId);
    if (index < 0) return 0;
    final base = coinPackAmounts[index];
    final isHotDeal = index == weeklyHotDealPackIndex();
    return base + bonusCoinsForPack(index, isFirstPurchase: isFirstPurchase, isHotDeal: isHotDeal);
  }
}
