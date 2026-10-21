import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sos_alerts';
  static const String _channelName = 'SOS alerts';
  static const String _channelDescription =
      'Emergency alerts from your group members.';

  static const String _campaignChannelId = 'campaigns';
  static const String _campaignChannelName = 'Announcements';
  static const String _campaignChannelDescription =
      'News, tips and announcements from Family Locator.';

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _campaignChannelId,
        _campaignChannelName,
        description: _campaignChannelDescription,
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showSos({
    required String senderName,
    required String groupName,
  }) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: 1,
      title: 'SOS from $senderName',
      body: '$senderName needs help in $groupName.',
      notificationDetails: details,
      payload: 'sos',
    );
  }

  Future<void> showCampaign({
    required String title,
    required String body,
  }) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _campaignChannelId,
        _campaignChannelName,
        channelDescription: _campaignChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'campaign',
    );
  }
}
