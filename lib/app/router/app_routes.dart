class AppRoutes {
  static const activate = '/activate';
  static const login = '/login';
  static const home = '/';
  static const intake = '/intake';
  static const jobs = '/jobs';
  static const invoices = '/invoices';
  static const vehicles = '/vehicles';
  static const voice = '/voice';
  static const parts = '/parts';
  static const customers = '/customers';
  static const schedule = '/schedule';
  static const reports = '/reports';
  static const settings = '/settings';
  static const vehicleNew = '/vehicle/new';
  static const vehicleHistory = '/vehicle/:id';
  static const addVisit = '/vehicle/:id/visit/new';
  static const editVisit = '/vehicle/:id/visit/:visitId/edit';

  static String vehicleHistoryPath(int id) => '/vehicle/$id';
  static String addVisitPath(int vehicleId) => '/vehicle/$vehicleId/visit/new';
  static String editVisitPath(int vehicleId, int visitId) => '/vehicle/$vehicleId/visit/$visitId/edit';
  static String voicePath({int? vehicleId}) {
    if (vehicleId == null) {
      return voice;
    }
    return '$voice?vehicleId=$vehicleId';
  }

  static String vehicleNewPath(String plate) =>
      '/vehicle/new?plate=${Uri.encodeQueryComponent(plate)}';
}
