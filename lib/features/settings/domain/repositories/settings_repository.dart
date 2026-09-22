import '../entities/shop_settings.dart';

abstract class SettingsRepository {
  Future<ShopSettings> read();
  Future<ShopSettings> save(ShopSettings settings);
}
