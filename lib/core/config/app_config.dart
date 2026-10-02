/// Centralised application configuration.
///
/// Every user facing reference to the application name is read from here, so
/// renaming the application is one edit in this file. The organisation,
/// MADRASSA.PK, is a different thing and is not stored here.
class AppConfig {
  const AppConfig._();

  /// Product name (English form, used for tooling / window titles).
  static const String appName = 'Madrassa Tarbiat App';

  /// Product name shown to users inside the Urdu interface.
  static const String appNameUrdu = 'مدرسہ تربیت ایپ';

  /// Secondary line displayed under the brand mark.
  static const String appTaglineUrdu = 'علم سے عمل، عمل سے اثر تک';

  /// Short Urdu description used on the welcome screen.
  static const String appDescriptionUrdu =
      'اپنی تربیت، عملی سرگرمیوں، کارگزاری اور پیش رفت کا ایک ہی جگہ ریکارڈ '
      'رکھیں اور اپنے مربی کی رہنمائی سے آگے بڑھیں۔';

  /// Displayed in the profile / settings screens.
  static const String appVersion = '1.0.0';

  /// Where Supabase sends the reader after an email link is opened.
  ///
  /// A confirmation or password link goes to Supabase first, which verifies
  /// the token and then redirects here. Left at Supabase's default of
  /// `http://localhost:3000` the phone has nothing to open and shows "this
  /// site can't be reached", so the account looks unconfirmed even though it
  /// was confirmed. This is a scheme the application itself registers, in the
  /// Android manifest and the iOS Info.plist, so Android and iOS hand the
  /// link straight back to the application.
  ///
  /// It must also be listed in the Supabase dashboard under
  /// Authentication -> URL Configuration -> Redirect URLs, or Supabase
  /// refuses to redirect to it.
  static const String authRedirectScheme = 'pk.madrassa.tarbiat';
  static const String authRedirectHost = 'auth-callback';
  static const String authRedirectUrl =
      '$authRedirectScheme://$authRedirectHost';

  /// The interface is Urdu-first and therefore right-to-left by default.
  static const String defaultLanguageCode = 'ur';
  static const String defaultCountryCode = 'PK';

}
