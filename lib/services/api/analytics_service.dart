import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/core/session_manager.dart';

class AnalyticsService {
  static Future<Map<String, dynamic>?> getDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/dashboard/summary'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (error) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPatientTrends() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/dashboard/patient-trends'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (error) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDiagnosisDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/dashboard/diagnosis-distribution'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (error) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTopMedicines() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/dashboard/top-medicines'),
        headers: AuthSession.headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (error) {
      return null;
    }
  }
}