import 'dart:async';
import 'dart:collection';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum AppNotificationCategory {
  budget,
  savings,
  health,
}

class AppNotificationEntry {
  const AppNotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.category,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
  final AppNotificationCategory category;
  final DateTime createdAt;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<AppNotificationEntry> _inbox = <AppNotificationEntry>[];
  final StreamController<List<AppNotificationEntry>> _inboxController =
      StreamController<List<AppNotificationEntry>>.broadcast();

  UnmodifiableListView<AppNotificationEntry> get inbox =>
      UnmodifiableListView(_inbox);

  Stream<List<AppNotificationEntry>> watchInbox() async* {
    yield List<AppNotificationEntry>.unmodifiable(_inbox);
    yield* _inboxController.stream;
  }

  void clearInbox() {
    _inbox.clear();
    _inboxController.add(List<AppNotificationEntry>.unmodifiable(_inbox));
  }

  void _addToInbox({
    required String title,
    required String body,
    required String payload,
    required AppNotificationCategory category,
  }) {
    _inbox.insert(
      0,
      AppNotificationEntry(
        id: DateTime.now().microsecondsSinceEpoch,
        title: title,
        body: body,
        payload: payload,
        category: category,
        createdAt: DateTime.now(),
      ),
    );
    _inboxController.add(List<AppNotificationEntry>.unmodifiable(_inbox));
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget spending alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    _addToInbox(
      title: title,
      body: body,
      payload: payload,
      category: AppNotificationCategory.budget,
    );
  }

  Future<void> showSavingsNudge({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'savings_nudges',
      'Savings Nudges',
      channelDescription: 'Notifications for savings goal nudges',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    _addToInbox(
      title: title,
      body: body,
      payload: payload,
      category: AppNotificationCategory.savings,
    );
  }

  Future<void> showHealthInsight({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'health_insights',
      'Health Insights',
      channelDescription: 'Notifications for financial health insights',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    _addToInbox(
      title: title,
      body: body,
      payload: payload,
      category: AppNotificationCategory.health,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
