abstract final class AppConfig {
  static const locationUpdateInterval = Duration(seconds: 30);
  static const staleLocationAfter = Duration(minutes: 5);
  static const minDistanceToUpload = 50.0;
  static const inviteCodelength = 6;
  static const defaultMapZoom = 15.0;
  static const String appLink = '';
  static const String playStoreUrl = '';
  static const String feedbackEmail = '';
  static const String fcmProjectId = 'family-locator-4551f';
  static const String fcmServiceAccountB64 = String.fromEnvironment(
    'FCM_SA_B64',
  );
}
