import 'package:flutter/material.dart';
import '../services/language_service.dart';

extension LocalizationExtension on BuildContext {
  String translate(String key) => LanguageService().translate(key);
}
