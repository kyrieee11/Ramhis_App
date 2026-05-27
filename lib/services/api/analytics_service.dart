import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';

class AnalyticsService {
  static Future<Map<String, dynamic>?> _getAsMap(
    String endpoint,
    String debugName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        print('$debugName Error Status: ${response.statusCode}');
        print('$debugName Error Body: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is List) {
        return {
          'data': decoded,
        };
      }

      return null;
    } catch (error) {
      print('$debugName Error: $error');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDashboardSummary() {
    return _getAsMap(
      '/dashboard/summary',
      'Dashboard Summary',
    );
  }

  static Future<Map<String, dynamic>?> getPatientTrends() {
    return _getAsMap(
      '/dashboard/patient-trends',
      'Patient Trends',
    );
  }

  static Future<Map<String, dynamic>?> getDiagnosisDistribution() {
    return _getAsMap(
      '/dashboard/diagnosis-distribution',
      'Diagnosis Distribution',
    );
  }

  static Future<Map<String, dynamic>?> getTopMedicines() {
    return _getAsMap(
      '/dashboard/top-medicines',
      'Top Medicines',
    );
  }
}