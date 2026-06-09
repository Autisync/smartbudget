import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pending "quick add" request raised from the bottom-nav add menu for
/// destinations whose add form is an in-screen modal rather than a route
/// (budgets and savings goals).
///
/// The nav sets this and navigates to the destination screen; that screen
/// listens, opens its add form once, and resets the value to null.
enum QuickAddTarget { budget, savings }

final pendingQuickAddProvider = StateProvider<QuickAddTarget?>((ref) => null);
