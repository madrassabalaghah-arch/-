/// Centralised application configuration.
///
/// The final product name has NOT been decided yet. Every user facing
/// reference to the application name must be read from here so that a single
/// edit in this file renames the entire application.
class AppConfig {
  const AppConfig._();

  /// Temporary product name (English form, used for tooling / window titles).
  static const String appName = 'MADRASSA.PK Graduate Platform';

  /// Temporary product name shown to users inside the Urdu interface.
  static const String appNameUrdu = 'کارواں فضلاء مدرسہ ڈاٹ پی کے';

  /// Secondary line displayed under the brand mark.
  static const String appTaglineUrdu = 'علم سے عمل، عمل سے اثر تک';

  /// Short Urdu description used on the welcome screen.
  static const String appDescriptionUrdu =
      'اپنی تربیت، عملی سرگرمیوں، کارگزاری اور پیش رفت کا ایک ہی جگہ ریکارڈ '
      'رکھیں اور اپنے مربی کی رہنمائی سے آگے بڑھیں۔';

  /// Displayed in the profile / settings screens.
  static const String appVersion = '1.0.0';

  /// The interface is Urdu-first and therefore right-to-left by default.
  static const String defaultLanguageCode = 'ur';
  static const String defaultCountryCode = 'PK';

}
