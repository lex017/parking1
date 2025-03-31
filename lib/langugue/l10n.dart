import 'package:flutter/material.dart';

class L10n {
  static final all = [
    const Locale('en', ''), // English
    const Locale('lo', ''), // Lao
  ];
}

class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get hello {
    // Return a string based on the selected language
    return 'Hello';
  }

  // You can add other localized strings here
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'lo'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
