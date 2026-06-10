import 'dart:async';
import 'dart:collection';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationType {
  budgetThresholdReached,
  subscriptionRenewalDue,
  savingsGoalMilestone,
  reportGenerated,
  suspiciousLogin,
  recurringBalanceWarning,
  scenarioRecommendation,
  monthlySummary,
  failedSync,
  securityAlert,
}

enum NotificationState { unread, read, archived, actioned }

enum NotificationChannel { local, push, inApp }

enum PushPermissionState {
  notDetermined,
  granted,
  denied,
  provisional,
  unsupported,
  error,
}

enum AppNotificationCategory { budget, savings, health, reports, security }

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.type,
    required this.createdAt,
    required this.channel,
    this.state = NotificationState.unread,
    this.confidence = 0,
  });

  final String id;
  final String title;
  final String body;
  final String payload;
  final NotificationType type;
  final DateTime createdAt;
  final NotificationChannel channel;
  final NotificationState state;
  final double confidence;

  bool get isRead => state != NotificationState.unread;

  AppNotificationCategory get category {
    switch (type) {
      case NotificationType.budgetThresholdReached:
      case NotificationType.recurringBalanceWarning:
      case NotificationType.scenarioRecommendation:
        return AppNotificationCategory.budget;
      case NotificationType.savingsGoalMilestone:
      case NotificationType.monthlySummary:
        return AppNotificationCategory.savings;
      case NotificationType.reportGenerated:
      case NotificationType.failedSync:
        return AppNotificationCategory.reports;
      case NotificationType.suspiciousLogin:
      case NotificationType.securityAlert:
        return AppNotificationCategory.security;
      case NotificationType.subscriptionRenewalDue:
        return AppNotificationCategory.health;
    }
  }

  NotificationModel copyWith({
    NotificationState? state,
    String? payload,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      payload: payload ?? this.payload,
      type: type,
      createdAt: createdAt,
      channel: channel,
      state: state ?? this.state,
      confidence: confidence,
    );
  }
}

typedef AppNotificationEntry = NotificationModel;

class NotificationRepository {
  final List<NotificationModel> _items = <NotificationModel>[];
  final StreamController<List<NotificationModel>> _controller =
      StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> watch() async* {
    yield List<NotificationModel>.unmodifiable(_items);
    yield* _controller.stream;
  }

  UnmodifiableListView<NotificationModel> get items =>
      UnmodifiableListView(_items);

  void add(NotificationModel model) {
    _items.insert(0, model);
    _publish();
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].state == NotificationState.unread) {
        _items[i] = _items[i].copyWith(state: NotificationState.read);
      }
    }
    _publish();
  }

  void markRead(String id) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(state: NotificationState.read);
      }
    }
    _publish();
  }

  void archive(String id) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(state: NotificationState.archived);
      }
    }
    _publish();
  }

  void clear() {
    _items.clear();
    _publish();
  }

  void _publish() {
    _controller.add(List<NotificationModel>.unmodifiable(_items));
  }
}

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({
    required void Function(String payload) onTap,
  }) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onTap(payload);
        }
      },
    );
  }

  /// Requests the OS-level permission needed to display local notifications.
  ///
  /// On Android 13+ (API 33) this triggers the POST_NOTIFICATIONS runtime
  /// prompt; without it notifications are silently dropped. On iOS it requests
  /// alert/badge/sound. Returns true if permission is granted (or implicitly
  /// granted on older Android versions where no runtime prompt exists).
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      // requestNotificationsPermission returns null on Android < 13, where the
      // permission is granted at install time.
      return granted ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> show(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'smartspend_dynamic',
      'SmartSpend Notifications',
      channelDescription: 'Dynamic SmartSpend notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'SmartSpend',
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      notification.createdAt.microsecondsSinceEpoch.remainder(2147483647),
      notification.title,
      notification.body,
      details,
      payload: notification.payload,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

@pragma('vm:entry-point')
Future<void> smartSpendFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Minimal by design; interaction routing is handled when app is resumed.
}

class PushNotificationService {
  PushNotificationService();

  FirebaseMessaging? _cachedMessaging;

  FirebaseMessaging? get _messaging {
    _cachedMessaging ??= _resolveMessaging();
    return _cachedMessaging;
  }

  FirebaseMessaging? _resolveMessaging() {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<RemoteMessage> get onForegroundMessage =>
      _messaging == null ? const Stream.empty() : FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp => _messaging == null
      ? const Stream.empty()
      : FirebaseMessaging.onMessageOpenedApp;

  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();

  Future<void> initialize() async {
    if (_messaging == null) return;
    FirebaseMessaging.onBackgroundMessage(
      smartSpendFirebaseMessagingBackgroundHandler,
    );
  }

  Future<PushPermissionState> getPermissionState() async {
    final messaging = _messaging;
    if (messaging == null) return PushPermissionState.unsupported;
    try {
      final settings = await messaging.getNotificationSettings();
      return _mapPermission(settings.authorizationStatus);
    } catch (_) {
      return PushPermissionState.error;
    }
  }

  Future<PushPermissionState> requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return PushPermissionState.unsupported;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return _mapPermission(settings.authorizationStatus);
    } catch (_) {
      return PushPermissionState.error;
    }
  }

  Future<String?> token() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      return messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<RemoteMessage?> initialMessage() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    return messaging.getInitialMessage();
  }

  PushPermissionState _mapPermission(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return PushPermissionState.granted;
      case AuthorizationStatus.denied:
        return PushPermissionState.denied;
      case AuthorizationStatus.provisional:
        return PushPermissionState.provisional;
      case AuthorizationStatus.notDetermined:
        return PushPermissionState.notDetermined;
    }
  }
}

class NotificationController {
  NotificationController(this._repository);

  final NotificationRepository _repository;

  Stream<List<NotificationModel>> watchInbox() => _repository.watch();

  void markRead(String id) => _repository.markRead(id);

  void markAllRead() => _repository.markAllRead();

  void archive(String id) => _repository.archive(id);

  void clear() => _repository.clear();
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final NotificationRepository _repository = NotificationRepository();
  late final NotificationController _controller =
      NotificationController(_repository);
  final LocalNotificationService _local = LocalNotificationService();
  final PushNotificationService _push = PushNotificationService();

  final StreamController<String> _routeController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  String? _latestFcmToken;

  NotificationController get notificationController => _controller;

  String? get latestFcmToken => _latestFcmToken;

  Stream<String> get routeStream => _routeController.stream;

  Stream<List<AppNotificationEntry>> watchInbox() => _repository.watch();

  UnmodifiableListView<AppNotificationEntry> get inbox => _repository.items;

  Future<void> initialize() async {
    if (_initialized) return;

    await _local.initialize(onTap: _onNotificationTapped);
    // Ask for the OS notification permission up front (Android 13+/iOS) so
    // dynamically-triggered local notifications can actually be displayed.
    await _local.requestPermission();

    try {
      if (Firebase.apps.isNotEmpty) {
        await _push.initialize();
        _bindPushStreams();
        _latestFcmToken = await _push.token();
      }
    } catch (_) {
      // Firebase runtime setup is optional; local notifications still work.
    }

    _initialized = true;
  }

  Future<PushPermissionState> getPushPermissionState() async {
    try {
      if (Firebase.apps.isEmpty) {
        return PushPermissionState.unsupported;
      }
      return _push.getPermissionState();
    } catch (_) {
      return PushPermissionState.error;
    }
  }

  Future<PushPermissionState> requestPushPermission() async {
    try {
      if (Firebase.apps.isEmpty) {
        return PushPermissionState.unsupported;
      }
      return _push.requestPermission();
    } catch (_) {
      return PushPermissionState.error;
    }
  }

  /// Requests the OS permission required to show local (on-device)
  /// notifications. Works independently of Firebase/push configuration.
  Future<bool> requestLocalPermission() => _local.requestPermission();

  void markRead(String id) => _repository.markRead(id);

  void archive(String id) => _repository.archive(id);

  void clearInbox() => _repository.clear();

  void markAllRead() => _repository.markAllRead();

  Future<void> showBudgetAlert({
    required String title,
    required String body,
    required String payload,
  }) {
    return _dispatch(
      type: NotificationType.budgetThresholdReached,
      title: title,
      body: body,
      payload: payload,
      channel: NotificationChannel.local,
    );
  }

  Future<void> showSavingsNudge({
    required String title,
    required String body,
    required String payload,
  }) {
    return _dispatch(
      type: NotificationType.savingsGoalMilestone,
      title: title,
      body: body,
      payload: payload,
      channel: NotificationChannel.local,
    );
  }

  Future<void> showHealthInsight({
    required String title,
    required String body,
    required String payload,
  }) {
    return _dispatch(
      type: NotificationType.recurringBalanceWarning,
      title: title,
      body: body,
      payload: payload,
      channel: NotificationChannel.local,
    );
  }

  Future<void> showReportGenerated({
    required String title,
    required String body,
    required String payload,
  }) {
    return _dispatch(
      type: NotificationType.reportGenerated,
      title: title,
      body: body,
      payload: payload,
      channel: NotificationChannel.local,
    );
  }

  Future<void> showSecurityAlert({
    required String title,
    required String body,
    required String payload,
  }) {
    return _dispatch(
      type: NotificationType.securityAlert,
      title: title,
      body: body,
      payload: payload,
      channel: NotificationChannel.local,
    );
  }

  Future<void> cancelAllNotifications() => _local.cancelAll();

  Future<void> _dispatch({
    required NotificationType type,
    required String title,
    required String body,
    required String payload,
    required NotificationChannel channel,
  }) async {
    final model = NotificationModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      payload: payload,
      type: type,
      createdAt: DateTime.now(),
      channel: channel,
    );

    _repository.add(model);
    if (channel == NotificationChannel.local) {
      await _local.show(model);
    }
  }

  void _bindPushStreams() {
    _push.onForegroundMessage.listen((message) {
      final model = _fromRemoteMessage(message, NotificationChannel.push);
      _repository.add(model);
      _local.show(model);
    });

    _push.onMessageOpenedApp.listen((message) {
      final model = _fromRemoteMessage(message, NotificationChannel.push);
      _repository.add(model);
      _onNotificationTapped(model.payload);
    });

    _push.onTokenRefresh.listen((token) {
      _latestFcmToken = token;
    });

    _push.initialMessage().then((message) {
      if (message == null) return;
      final model = _fromRemoteMessage(message, NotificationChannel.push);
      _repository.add(model);
      _onNotificationTapped(model.payload);
    });
  }

  NotificationModel _fromRemoteMessage(
    RemoteMessage message,
    NotificationChannel channel,
  ) {
    final payload = message.data['route'] as String? ?? '/notifications';
    final typeName = message.data['type'] as String?;
    final type = _typeFrom(typeName);
    return NotificationModel(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'SmartSpend update',
      body: message.notification?.body ?? 'You have a new update.',
      payload: payload,
      type: type,
      createdAt: DateTime.now(),
      channel: channel,
    );
  }

  NotificationType _typeFrom(String? raw) {
    if (raw == null) return NotificationType.monthlySummary;
    switch (raw) {
      case 'budget_alert':
        return NotificationType.budgetThresholdReached;
      case 'subscription_renewal':
        return NotificationType.subscriptionRenewalDue;
      case 'savings_milestone':
        return NotificationType.savingsGoalMilestone;
      case 'report_generated':
        return NotificationType.reportGenerated;
      case 'suspicious_login':
        return NotificationType.suspiciousLogin;
      case 'recurring_warning':
        return NotificationType.recurringBalanceWarning;
      case 'scenario_recommendation':
        return NotificationType.scenarioRecommendation;
      case 'failed_sync':
        return NotificationType.failedSync;
      case 'security_alert':
        return NotificationType.securityAlert;
      case 'monthly_summary':
      default:
        return NotificationType.monthlySummary;
    }
  }

  void _onNotificationTapped(String payload) {
    _routeController.add(payload);
  }

  static String routeForType(NotificationType type) {
    switch (type) {
      case NotificationType.budgetThresholdReached:
        return '/budgets';
      case NotificationType.subscriptionRenewalDue:
        return '/subscriptions';
      case NotificationType.savingsGoalMilestone:
        return '/savings';
      case NotificationType.reportGenerated:
        return '/reports';
      case NotificationType.suspiciousLogin:
      case NotificationType.securityAlert:
        return '/security';
      case NotificationType.recurringBalanceWarning:
        return '/balance-sheet';
      case NotificationType.scenarioRecommendation:
        return '/scenario-lab';
      case NotificationType.monthlySummary:
      case NotificationType.failedSync:
        return '/notifications';
    }
  }
}
