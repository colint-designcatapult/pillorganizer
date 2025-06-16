import 'package:app/api/api.dart';
import 'package:flutter/foundation.dart';

class CaregiverProvider with ChangeNotifier {
  Future<void> validateCaregiverCode({required String code}) async {
    await client.validateCaregiverCode(code);
  }
}
