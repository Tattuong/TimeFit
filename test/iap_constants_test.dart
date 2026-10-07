import 'package:flutter_test/flutter_test.dart';
import 'package:timefit/core/constants/iap_constants.dart';
import 'package:timefit/core/services/iap_config_service.dart';
import 'package:timefit/models/shop_item.dart';

void main() {
  test('TimeFit IAP ids and N294 endpoint', () {
    expect(IapConstants.productPrefix, 'tf');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N294.json');
    expect(IapConstants.coinPackIds.first, 'tf_pack_1');
    expect(IapConstants.coinPackIds.last, 'tf_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'tf_remove_ads');
    expect(IapConstants.proProductId, 'tf_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'tf_remove_ads', 'tf_pro']));
    expect(IapConstants.coinsForProduct('tf_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'TimeFit'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'TimeFit', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'TimeFit');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
