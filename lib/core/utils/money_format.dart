import 'package:intl/intl.dart';

class MoneyFormat {
  MoneyFormat._();

  static final _fa = NumberFormat.decimalPattern('fa');

  static String toman(int amount) => '${_fa.format(amount)} تومان';

  static String compact(int amount) => _fa.format(amount);
}
