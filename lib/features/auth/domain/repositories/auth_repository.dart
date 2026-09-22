import '../entities/mechanic_account.dart';

abstract class AuthRepository {
  MechanicAccount? get currentAccount;
  Future<MechanicAccount> login({
    required String phone,
    required String password,
  });
  Future<void> logout();
}
