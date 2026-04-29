import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:ramhis_app/core/session_manager.dart';
import 'package:ramhis_app/models/content_model.dart';

class ContentService {
  Future<HomepageContentModel?> getHomepageContent() async {
    try {
      final response = await AuthApi.get('/content/homepage_content');

      debugPrint('HOME CONTENT STATUS: ${response.statusCode}');
      

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded == null) return null;

      return HomepageContentModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error) {
      debugPrint('HOME CONTENT ERROR: $error');
      return null;
    }
  }
}