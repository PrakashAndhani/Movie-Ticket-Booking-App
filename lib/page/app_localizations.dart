import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login Now',
      'enter_details': 'Please enter the following details to proceed',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'dont_have_account': "Don't have an account?",
      'register': 'Register',
    },
    'gu': {
      'login': 'લૉગિન કરો',
      'enter_details': 'કૃપા કરીને આગળ વધવા માટે વિગતો દાખલ કરો',
      'email': 'ઇમેઇલ',
      'password': 'પાસવર્ડ',
      'forgot_password': 'પાસવર્ડ ભૂલી ગયા છો?',
      'dont_have_account': "એકાઉન્ટ નથી?",
      'register': 'રજીસ્ટર',
    },
    'hi': {
      'login': 'लॉग इन करें',
      'enter_details': 'कृपया आगे बढ़ने के लिए विवरण दर्ज करें',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड भूल गए?',
      'dont_have_account': "खाता नहीं है?",
      'register': 'रजिस्टर करें',
    },
  };

  String getText(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'gu', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
