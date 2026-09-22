import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/shop_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<ShopSettings> read() async => _store.settings;

  @override
  Future<ShopSettings> save(ShopSettings settings) async {
    _store.settings = settings;
    return settings;
  }
}
