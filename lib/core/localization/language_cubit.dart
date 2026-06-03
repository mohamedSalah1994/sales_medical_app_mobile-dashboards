import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_state.dart';

Locale _localeForLanguageCode(String? code) {
  final normalized = (code ?? 'en').toLowerCase().trim();
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == normalized) {
      return supported;
    }
  }
  return const Locale('en');
}

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageState.initial()) {
    _loadSavedLanguage();
  }

  static const String _languageKey = 'app_language';

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    final locale = _localeForLanguageCode(saved);
    if (saved != null &&
        saved.toLowerCase().trim() != locale.languageCode) {
      await prefs.setString(_languageKey, locale.languageCode);
    }
    emit(LanguageState(locale: locale));
  }

  Future<void> changeLanguage(Locale locale) async {
    final resolved = _localeForLanguageCode(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, resolved.languageCode);
    emit(LanguageState(locale: resolved));
  }

  Future<void> setEnglish() async {
    await changeLanguage(const Locale('en'));
  }

  Future<void> setArabic() async {
    await changeLanguage(const Locale('ar'));
  }
}

