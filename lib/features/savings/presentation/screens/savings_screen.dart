import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/components/dialogs/confirm_action_dialog.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/components/shared/slidable_edge_clip.dart';
import 'package:smartbudget/components/sheets/app_bottom_action_sheet.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/providers/quick_add_provider.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/theme/input_styles.dart';
import 'package:smartbudget/core/widgets/app_feedback.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/features/savings/presentation/providers/savings_provider.dart';
import 'package:smartbudget/domain/entities/savings_goal.dart';
import 'package:smartbudget/data/models/tables.dart' show GoalPriority;
import 'package:smartbudget/data/models/tables.dart' show TransactionType;
import 'package:smartbudget/domain/entities/account.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/features/accounts/presentation/providers/account_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:smartbudget/core/widgets/animated_list_item.dart';
import 'package:smartbudget/core/utils/money_utils.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  static const _surplusDismissedUntilKey =
      'savings.monthlySurplus.dismissedUntil';
  static const _surplusDismissedSignatureKey =
      'savings.monthlySurplus.dismissedSignature';
  static const _surplusShownAtKey = 'savings.monthlySurplus.shownAt';
  static const _surplusShownSignatureKey =
      'savings.monthlySurplus.shownSignature';
  static const _pausedGoalIdsKey = 'savings.goalStatus.pausedIds';
  static const _archivedGoalIdsKey = 'savings.goalStatus.archivedIds';
  static const _goalMilestonesKey = 'savings.goalMilestones.v1';

  ProviderSubscription<AsyncValue<List<SavingsNudge>>>? _nudgeSubscription;
  final Set<String> _notifiedNudgeKeys = <String>{};
  bool _isAppBarScrolled = false;
  DateTime? _surplusDismissedUntil;
  String? _surplusDismissedSignature;
  DateTime? _surplusShownAt;
  String? _surplusShownSignature;
  Set<String> _pausedGoalIds = <String>{};
  Set<String> _archivedGoalIds = <String>{};
  Map<String, int> _goalMilestones = <String, int>{};
  final List<_MilestonePopupEvent> _milestoneQueue = <_MilestonePopupEvent>[];
  bool _isShowingMilestonePopup = false;
  bool _goalMilestonesLoaded = false;
  bool _surplusStateLoaded = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  void initState() {
    super.initState();
    _loadSurplusDismissState();
    _loadGoalLifecycleState();
    _loadGoalMilestones();
    // Consume a quick-add request raised from the bottom-nav "+" menu.
    _maybeHandleQuickAdd(ref.read(pendingQuickAddProvider));
    _nudgeSubscription = ref.listenManual<AsyncValue<List<SavingsNudge>>>(
      savingsNudgesProvider,
      (previous, next) {
        next.whenData((nudges) async {
          final notificationService = ref.read(notificationServiceProvider);
          final preferencesService =
              ref.read(notificationPreferencesServiceProvider);
          for (final nudge in nudges.take(2)) {
            final key = '${nudge.goalId}-${nudge.title}';
            if (_notifiedNudgeKeys.contains(key)) continue;

            final canSend =
                await preferencesService.shouldDispatch('savingsNudges');
            if (!canSend) break;

            _notifiedNudgeKeys.add(key);
            await notificationService.showSavingsNudge(
              title: nudge.title,
              body: nudge.message,
              payload: nudge.goalId,
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _nudgeSubscription?.close();
    super.dispose();
  }

  void _maybeHandleQuickAdd(QuickAddTarget? target) {
    if (target != QuickAddTarget.savings) return;
    // Defer to after the current build/lifecycle: mutating a provider during
    // initState or build is disallowed by Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingQuickAddProvider.notifier).state = null;
      _openGoalForm(ref);
    });
  }

  Future<void> _loadSurplusDismissState() async {
    final storage = ref.read(secureStorageProvider);
    final rawUntil = await storage.read(key: _surplusDismissedUntilKey);
    final rawSignature = await storage.read(key: _surplusDismissedSignatureKey);
    final rawShownAt = await storage.read(key: _surplusShownAtKey);
    final rawShownSignature =
        await storage.read(key: _surplusShownSignatureKey);
    if (!mounted) return;
    setState(() {
      _surplusDismissedUntil =
          rawUntil == null ? null : DateTime.tryParse(rawUntil);
      _surplusDismissedSignature = rawSignature;
      _surplusShownAt =
          rawShownAt == null ? null : DateTime.tryParse(rawShownAt);
      _surplusShownSignature = rawShownSignature;
      _surplusStateLoaded = true;
    });
  }

  Set<String> _decodeIdSet(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toSet();
      }
    } catch (_) {
      return <String>{};
    }
    return <String>{};
  }

  Future<void> _loadGoalLifecycleState() async {
    final storage = ref.read(secureStorageProvider);
    final pausedRaw = await storage.read(key: _pausedGoalIdsKey);
    final archivedRaw = await storage.read(key: _archivedGoalIdsKey);
    if (!mounted) return;
    setState(() {
      _pausedGoalIds = _decodeIdSet(pausedRaw);
      _archivedGoalIds = _decodeIdSet(archivedRaw);
    });
  }

  Map<String, int> _decodeMilestoneMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (key, value) => MapEntry(key, int.tryParse('$value') ?? 0),
        );
      }
    } catch (_) {
      return <String, int>{};
    }
    return <String, int>{};
  }

  Future<void> _loadGoalMilestones() async {
    final storage = ref.read(secureStorageProvider);
    final raw = await storage.read(key: _goalMilestonesKey);
    if (!mounted) return;
    setState(() {
      _goalMilestones = _decodeMilestoneMap(raw);
      _goalMilestonesLoaded = true;
    });
  }

  Future<void> _persistGoalMilestones() async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(
      key: _goalMilestonesKey,
      value: jsonEncode(_goalMilestones),
    );
  }

  int _milestoneForProgress(double progress) {
    if (progress >= 1.0) return 100;
    if (progress >= 0.75) return 75;
    if (progress >= 0.50) return 50;
    if (progress >= 0.25) return 25;
    return 0;
  }

  void _trackGoalMilestone(SavingsGoal goal, double progress) {
    if (!_goalMilestonesLoaded) return;
    final l10n = AppLocalizations.of(context)!;
    final reachedMilestone = _milestoneForProgress(progress);
    if (reachedMilestone <= 0) return;

    final previousMilestone = _goalMilestones[goal.id] ?? 0;
    if (reachedMilestone <= previousMilestone) return;

    _goalMilestones = {
      ..._goalMilestones,
      goal.id: reachedMilestone,
    };
    _persistGoalMilestones();

    _enqueueMilestonePopup(
      _MilestonePopupEvent(
        title: l10n.savingsMilestoneReached,
        headline: '${goal.title}: $reachedMilestone% complete',
        message: _savingsMilestoneMessage(l10n, reachedMilestone),
      ),
    );
  }

  String _savingsMilestoneMessage(AppLocalizations l10n, int milestone) {
    switch (milestone) {
      case 25:
        return l10n.savingsMilestoneGreatStart;
      case 50:
        return l10n.savingsMilestoneHalfway;
      case 75:
        return l10n.savingsMilestoneAmazing;
      case 100:
        return l10n.savingsMilestoneAchieved;
      default:
        return l10n.savingsMilestoneNiceProgress;
    }
  }

  void _enqueueMilestonePopup(_MilestonePopupEvent event) {
    _milestoneQueue.add(event);
    _drainMilestoneQueue();
  }

  Future<void> _drainMilestoneQueue() async {
    if (_isShowingMilestonePopup || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _isShowingMilestonePopup = true;
    while (_milestoneQueue.isNotEmpty && mounted) {
      final event = _milestoneQueue.removeAt(0);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration_outlined,
                  color: AppColors.income(Theme.of(context).brightness)),
              const SizedBox(width: 8),
              Expanded(child: Text(event.title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.headline,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(event.message),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.savingsKeepGoing),
            ),
          ],
        ),
      );
    }
    _isShowingMilestonePopup = false;
  }

  Future<void> _persistGoalLifecycleState() async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(
      key: _pausedGoalIdsKey,
      value: jsonEncode(_pausedGoalIds.toList(growable: false)),
    );
    await storage.write(
      key: _archivedGoalIdsKey,
      value: jsonEncode(_archivedGoalIds.toList(growable: false)),
    );
  }

  Future<void> _setGoalLifecycleState(
    String goalId, {
    bool? paused,
    bool? archived,
  }) async {
    final nextPaused = <String>{..._pausedGoalIds};
    final nextArchived = <String>{..._archivedGoalIds};

    if (paused != null) {
      if (paused) {
        nextPaused.add(goalId);
      } else {
        nextPaused.remove(goalId);
      }
    }
    if (archived != null) {
      if (archived) {
        nextArchived.add(goalId);
      } else {
        nextArchived.remove(goalId);
      }
    }

    if (!mounted) return;
    setState(() {
      _pausedGoalIds = nextPaused;
      _archivedGoalIds = nextArchived;
    });
    await _persistGoalLifecycleState();
  }

  Future<void> _cleanupGoalLifecycleState(List<SavingsGoal> goals) async {
    final goalIds = goals.map((goal) => goal.id).toSet();
    final nextPaused = _pausedGoalIds.intersection(goalIds);
    final nextArchived = _archivedGoalIds.intersection(goalIds);
    final changed = nextPaused.length != _pausedGoalIds.length ||
        nextArchived.length != _archivedGoalIds.length;
    if (!changed) return;
    if (!mounted) return;
    setState(() {
      _pausedGoalIds = nextPaused;
      _archivedGoalIds = nextArchived;
    });
    await _persistGoalLifecycleState();
  }

  String _surplusSignature(double monthlySurplus, List<SavingsGoal> goals) {
    final totalRemaining = goals.fold<double>(
      0,
      (sum, goal) =>
          sum +
          (goal.targetAmount - goal.savedAmount).clamp(0, double.infinity),
    );
    return '${monthlySurplus.toStringAsFixed(2)}:${goals.length}:${totalRemaining.toStringAsFixed(2)}';
  }

  bool _isSurplusCardVisible(double monthlySurplus, List<SavingsGoal> goals) {
    if (!_surplusStateLoaded) return false;
    if (monthlySurplus <= 0) return false;
    final signature = _surplusSignature(monthlySurplus, goals);

    final isNewSignature = _surplusShownSignature != signature;
    if (isNewSignature || _surplusShownAt == null) {
      return true;
    }

    final shownWithin24Hours =
        DateTime.now().difference(_surplusShownAt!).inHours < 24;
    if (!shownWithin24Hours) {
      return false;
    }

    final isDismissedForSignature = _surplusDismissedSignature == signature &&
        _surplusDismissedUntil != null;
    if (isDismissedForSignature &&
        DateTime.now().isBefore(_surplusDismissedUntil!)) {
      return false;
    }

    return true;
  }

  Future<void> _markSurplusCardShownIfNeeded(
    double monthlySurplus,
    List<SavingsGoal> goals,
  ) async {
    if (!_surplusStateLoaded) return;
    final signature = _surplusSignature(monthlySurplus, goals);
    final alreadyMarkedForSignature =
        _surplusShownSignature == signature && _surplusShownAt != null;
    if (alreadyMarkedForSignature) return;

    final now = DateTime.now();
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _surplusShownAtKey, value: now.toIso8601String());
    await storage.write(key: _surplusShownSignatureKey, value: signature);

    if (!mounted) return;
    setState(() {
      _surplusShownAt = now;
      _surplusShownSignature = signature;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuickAddTarget?>(pendingQuickAddProvider, (_, next) {
      _maybeHandleQuickAdd(next);
    });
    final l10n = AppLocalizations.of(context)!;
    final savingsAsync = ref.watch(savingsGoalListProvider);
    final nudgesAsync = ref.watch(savingsNudgesProvider);
    final monthlyTransactionsAsync = ref.watch(recentTransactionsProvider);
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.savingsGoalsTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withOpacity( _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'savings-appbar-blur-on',
          offKey: 'savings-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: savingsAsync.when(
          data: (goals) {
            final goalIds = goals.map((goal) => goal.id).toSet();
            if (_pausedGoalIds.difference(goalIds).isNotEmpty ||
                _archivedGoalIds.difference(goalIds).isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cleanupGoalLifecycleState(goals);
              });
            }

            final archivedGoals = goals
                .where((goal) => _archivedGoalIds.contains(goal.id))
                .toList(growable: false);
            final pausedGoals = goals
                .where((goal) =>
                    !_archivedGoalIds.contains(goal.id) &&
                    _pausedGoalIds.contains(goal.id))
                .toList(growable: false);
            final activeGoals = goals
                .where((goal) =>
                    !_archivedGoalIds.contains(goal.id) &&
                    !_pausedGoalIds.contains(goal.id))
                .toList(growable: false);

            final now = DateTime.now();
            final monthlySurplus = monthlyTransactionsAsync.maybeWhen(
              data: (transactions) {
                final income = transactions
                    .where((tx) => tx.type == TransactionType.income)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);
                final expense = transactions
                    .where((tx) => tx.type == TransactionType.expense)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);
                return income - expense;
              },
              orElse: () => 0.0,
            );
            final totalTarget = activeGoals.fold<double>(
              0.0,
              (sum, goal) => sum + goal.targetAmount,
            );
            final totalSaved = activeGoals.fold<double>(
              0.0,
              (sum, goal) => sum + goal.savedAmount,
            );
            final atRiskGoals = activeGoals.where((goal) {
              if (goal.deadline == null || goal.targetAmount <= 0) return false;
              final createdAt = goal.createdAt ?? now;
              final totalDays = goal.deadline!.difference(createdAt).inDays;
              if (totalDays <= 0) return false;
              final elapsedDays = now.difference(createdAt).inDays;
              final expectedProgress =
                  (elapsedDays / totalDays).clamp(0.0, 1.0);
              final actualProgress =
                  (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
              return actualProgress + 0.05 < expectedProgress;
            }).length;

            if (activeGoals.isEmpty &&
                pausedGoals.isEmpty &&
                archivedGoals.isEmpty) {
              return AppEmptyState(
                icon: Icons.savings_outlined,
                title: l10n.savingsEmptyTitle,
                message: l10n.savingsEmptySubtitle,
                lottieAsset: 'assets/animations/empty_savings.json',
                action: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(220.0, 320.0)
                      .toDouble(),
                  child: FilledButton.icon(
                    onPressed: () => _openGoalForm(ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.savingsCreateGoal),
                  ),
                ),
              );
            }

            final decisionMessage = atRiskGoals > 0
                ? l10n.savingsGoalsBehindPace(atRiskGoals)
                : monthlySurplus > 0
                    ? l10n.savingsMonthlySurplusMessage(
                        currencyFormat.format(monthlySurplus),
                      )
                    : l10n.savingsSteadyProgress;

            return ListView(
              // Clear the floating bottom nav + safe area so the last goal card
              // and its "Suggested / month" line are never hidden behind it.
              padding: EdgeInsets.fromLTRB(
                  12, 12, 12, 120 + MediaQuery.paddingOf(context).bottom),
              children: [
                // Savings Portfolio Card
                SavingsPortfolioCard(
                  totalTarget: totalTarget,
                  totalSaved: totalSaved,
                  atRiskGoals: atRiskGoals,
                  goalsCount: activeGoals.length,
                  decisionMessage: decisionMessage,
                  currencyFormat: currencyFormat,
                  monthlySurplus: monthlySurplus,
                ),
                const SizedBox(height: 16),

                // Nudges Section
                nudgesAsync.when(
                  data: (nudges) {
                    if (nudges.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _SavingsNudgeCard(nudges: nudges.take(2).toList()),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Surplus Allocation Section
                if (_isSurplusCardVisible(monthlySurplus, activeGoals))
                  Column(
                    children: [
                      Builder(
                        builder: (context) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _markSurplusCardShownIfNeeded(
                              monthlySurplus,
                              activeGoals,
                            );
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                      _SavingsSurplusCard(
                        monthlySurplus: monthlySurplus,
                        currencyFormat: currencyFormat,
                        onOpenAllocator: () => _openSurplusSimulationSheet(
                          goals: activeGoals,
                          monthlySurplus: monthlySurplus,
                          currencyFormat: currencyFormat,
                          currencyCode: appCurrency,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Savings Goals
                if (activeGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SmartEmptyState(
                      icon: Icons.pause_circle_outline,
                      title: l10n.savingsNoActiveGoals,
                      message: l10n.savingsAllPausedOrArchived,
                      lottieAsset: 'assets/animations/empty_savings.json',
                    ),
                  ),
                ...activeGoals.mapIndexed((idx, goal) {
                  final progress = goal.targetAmount > 0
                      ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _trackGoalMilestone(goal, progress);
                  });
                  final remaining =
                      (goal.targetAmount - goal.savedAmount).clamp(
                    0.0,
                    double.infinity,
                  );
                  final hasDeadline = goal.deadline != null;
                  final monthsRemaining = hasDeadline
                      ? (((goal.deadline!.difference(now).inDays) / 30).ceil())
                          .clamp(1, 120)
                      : 0;
                  final suggestedMonthly =
                      hasDeadline ? remaining / monthsRemaining : remaining / 6;
                  final projectedLate = hasDeadline && suggestedMonthly > 0
                      ? _calculateProjectedDelayMonths(
                          goal,
                          now,
                        )
                      : 0;

                  final statusColor = _goalStatusColor(
                    Theme.of(context).brightness,
                    progress,
                    projectedLate,
                  );

                  return AnimatedListItem(
                    index: idx,
                    child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Slidable(
                      key: ValueKey('savings-goal-${goal.id}'),
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.30,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _handleGoalAction(
                              action: 'pause',
                              goal: goal,
                              currencyFormat: currencyFormat,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            icon: Icons.pause_circle_outline_rounded,
                            label: l10n.commonPause,
                            borderRadius:
                                BorderRadius.circular(UiTokens.radiusXl),
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.30,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _handleGoalAction(
                              action: 'archive',
                              goal: goal,
                              currencyFormat: currencyFormat,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.tertiary,
                            foregroundColor: Colors.white,
                            icon: Icons.archive_outlined,
                            label: l10n.commonArchive,
                            borderRadius:
                                BorderRadius.circular(UiTokens.radiusXl),
                          ),
                        ],
                      ),
                      child: SwipeableCard(
                        radius: UiTokens.radiusXl,
                        child: _SavingsGoalCard(
                          goal: goal,
                          progress: progress,
                          remaining: remaining,
                          statusColor: statusColor,
                          statusLabel:
                              _goalStatusLabel(l10n, progress, projectedLate),
                          suggestedMonthly: suggestedMonthly,
                          projectedLate: projectedLate,
                          monthsRemaining: monthsRemaining,
                          hasDeadline: hasDeadline,
                          currencyFormat: currencyFormat,
                          l10n: l10n,
                          onActionSelected: (action) => _handleGoalAction(
                            action: action,
                            goal: goal,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      ),
                    ),
                    ),
                    ); // AnimatedListItem
                }),
                if (pausedGoals.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.savingsPausedPlansTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...pausedGoals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SavingsDormantGoalCard(
                        goal: goal,
                        currencyFormat: currencyFormat,
                        statusLabel: l10n.savingsPausedLabel,
                        onRestore: () => _handleGoalAction(
                          action: 'resume',
                          goal: goal,
                          currencyFormat: currencyFormat,
                        ),
                        onDelete: () => _handleGoalAction(
                          action: 'delete',
                          goal: goal,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                    ),
                  ),
                ],
                if (archivedGoals.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.savingsArchivedPlansTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...archivedGoals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SavingsDormantGoalCard(
                        goal: goal,
                        currencyFormat: currencyFormat,
                        statusLabel: l10n.savingsArchivedLabel,
                        onRestore: () => _handleGoalAction(
                          action: 'unarchive',
                          goal: goal,
                          currencyFormat: currencyFormat,
                        ),
                        onDelete: () => _handleGoalAction(
                          action: 'delete',
                          goal: goal,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => AppSkeleton(
              height: index == 0 ? 148 : 190,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: 4,
          ),
          error: (err, st) => AppErrorState(
            title: l10n.savingsListErrorTitle,
            message: l10n.savingsListErrorMessage,
            actionLabel: l10n.commonRetry,
            onAction: () => ref.invalidate(savingsGoalListProvider),
          ),
        ),
      ),
    );
  }

  int _calculateProjectedDelayMonths(SavingsGoal goal, DateTime now) {
    final elapsedMonths =
        (((now.difference(goal.createdAt ?? now).inDays) / 30).clamp(1, 120))
            .toDouble();
    final currentRate = goal.savedAmount / elapsedMonths;
    if (currentRate <= 0 || goal.deadline == null) return 0;

    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
      0,
      double.infinity,
    );
    final neededMonths = (remaining / currentRate).ceil();
    final monthsUntilDeadline =
        ((goal.deadline!.difference(now).inDays) / 30).ceil();
    return (neededMonths - monthsUntilDeadline).clamp(0, 120);
  }

  Future<void> _allocateSurplusToTopGoal(
    List<SavingsGoal> goals,
    double amount,
  ) async {
    if (goals.isEmpty) return;

    final sorted = [...goals]..sort((a, b) {
        final aRemaining = a.targetAmount - a.savedAmount;
        final bRemaining = b.targetAmount - b.savedAmount;
        return aRemaining.compareTo(bRemaining);
      });
    final target = sorted.first;
    final newSaved =
        (target.savedAmount + amount).clamp(0, target.targetAmount).toDouble();
    final applied = newSaved - target.savedAmount;
    if (applied <= 0) return;

    // Debit the allocated cash from the default Cash account so the dashboard's
    // cash-on-hand balance reflects the surplus that was set aside. Recorded as
    // a transfer, so it stays out of the income/expense and budget totals.
    final appCurrency = ref.read(appCurrencyControllerProvider);
    await ref.read(transactionListProvider().notifier).addTransaction(
          Transaction(
            id: const Uuid().v4(),
            accountId: DefaultAccountIds.cash,
            amount: applied,
            currency: appCurrency,
            type: TransactionType.transfer,
            category: 'Savings',
            date: DateTime.now(),
            note: target.id,
          ),
        );

    final updated = target.copyWith(savedAmount: newSaved);
    await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(updated);
  }

  Future<void> _openSurplusSimulationSheet({
    required List<SavingsGoal> goals,
    required double monthlySurplus,
    required NumberFormat currencyFormat,
    required String currencyCode,
  }) async {
    if (goals.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final result = await AppFormSheet.show<_SurplusSimulationResult>(
      context,
      builder: (_) => _SurplusSimulationSheet(
        goals: goals,
        monthlySurplus: monthlySurplus,
        currencyFormat: currencyFormat,
        currencyCode: currencyCode,
      ),
    );
    if (!mounted) return;

    if (result == null) {
      AppFeedback.show(
        context,
        message: l10n.savingsSurplusCancelled,
        type: AppFeedbackType.info,
      );
      return;
    }

    if (!result.confirmed) {
      AppFeedback.show(
        context,
        message: l10n.savingsSimulationSavedNoApply,
        type: AppFeedbackType.info,
      );
      return;
    }

    if (result.amount <= 0) {
      AppFeedback.show(
        context,
        message: l10n.savingsEnterAmountAboveZero,
        type: AppFeedbackType.error,
      );
      return;
    }

    await _allocateSurplusToTopGoal(goals, result.amount);
    if (!mounted) return;
    AppFeedback.show(
      context,
      message:
          'Applied ${currencyFormat.format(result.amount)} to your top-priority goal.',
      type: AppFeedbackType.success,
    );
  }

  Future<void> _handleGoalAction({
    required String action,
    required SavingsGoal goal,
    required NumberFormat currencyFormat,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'addFunds':
        await _openContributionDialog(context, ref, goal);
        return;
      case 'simulate':
        _showSimulation(context, goal, 50, currencyFormat);
        return;
      case 'setPriority':
        await _pickGoalPriority(goal);
        return;
      case 'edit':
        await _openGoalForm(ref, existingGoal: goal);
        return;
      case 'pause':
        await _setGoalLifecycleState(
          goal.id,
          paused: true,
          archived: false,
        );
        await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(
              goal.copyWith(autoAllocate: false),
            );
        break;
      case 'resume':
        await _setGoalLifecycleState(
          goal.id,
          paused: false,
          archived: false,
        );
        break;
      case 'complete':
        await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(
              goal.copyWith(savedAmount: goal.targetAmount),
            );
        break;
      case 'archive':
        final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmActionDialog(
                title: l10n.savingsArchiveGoalTitle,
                message: l10n.savingsArchiveConfirmation,
                confirmLabel: l10n.commonArchive,
              ),
            ) ??
            false;
        if (!confirm) return;
        await _setGoalLifecycleState(
          goal.id,
          paused: false,
          archived: true,
        );
        await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(
              goal.copyWith(autoAllocate: false),
            );
        break;
      case 'unarchive':
        await _setGoalLifecycleState(
          goal.id,
          archived: false,
          paused: false,
        );
        break;
      case 'delete':
        final deleteConfirm = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmActionDialog(
                title: l10n.savingsDeleteGoalTitle,
                message: l10n.savingsDeleteConfirmation,
                confirmLabel: l10n.delete,
              ),
            ) ??
            false;
        if (!deleteConfirm) return;
        await _setGoalLifecycleState(
          goal.id,
          paused: false,
          archived: false,
        );
        await ref
            .read(savingsGoalListProvider.notifier)
            .deleteSavingsGoal(goal.id);
        break;
      default:
        return;
    }

    if (!mounted) return;
    AppFeedback.show(
      context,
      message: l10n.savingsGoalUpdated,
      type: AppFeedbackType.success,
    );
  }

  Future<void> _pickGoalPriority(SavingsGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await AppBottomActionSheet.show(
      context,
      title: l10n.savingsSetPriorityTitle,
      actions: [
        AppBottomAction(
          value: 'high',
          label: l10n.savingsPriorityHigh,
          icon: Icons.priority_high,
        ),
        AppBottomAction(
          value: 'medium',
          label: l10n.savingsPriorityMedium,
          icon: Icons.drag_indicator,
        ),
        AppBottomAction(
          value: 'low',
          label: l10n.savingsPriorityLow,
          icon: Icons.south,
        ),
      ],
    );

    if (selected == null) return;
    final priority = switch (selected) {
      'high' => GoalPriority.high,
      'medium' => GoalPriority.medium,
      _ => GoalPriority.low,
    };
    await ref.read(savingsGoalListProvider.notifier).updateSavingsGoal(
          goal.copyWith(priority: priority),
        );
    if (!mounted) return;
    AppFeedback.show(
      context,
      message: l10n.savingsPriorityUpdated,
      type: AppFeedbackType.success,
    );
  }

  Future<void> _openGoalForm(
    WidgetRef ref, {
    SavingsGoal? existingGoal,
  }) async {
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final result = await AppFormSheet.show<_SavingsGoalFormResult>(
      context,
      builder: (_) => _SavingsGoalFormSheet(
        existingGoal: existingGoal,
        currencySymbol: CurrencyUtils.symbol(appCurrency),
        currencyCode: appCurrency,
      ),
    );

    if (result == null) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final goal = SavingsGoal(
      id: existingGoal?.id ?? const Uuid().v4(),
      title: result.title,
      targetAmount: result.targetAmount,
      savedAmount: result.savedAmount,
      deadline: result.deadline,
      priority: result.priority,
      color: existingGoal?.color,
      autoAllocate: result.autoAllocate,
      createdAt: existingGoal?.createdAt ?? DateTime.now(),
    );

    AppFeedbackService.showLoading(
      context,
      existingGoal == null ? l10n.savingsSaving : l10n.savingsUpdating,
    );
    try {
      if (existingGoal == null) {
        await ref.read(savingsGoalListProvider.notifier).addSavingsGoal(goal);
      } else {
        await ref
            .read(savingsGoalListProvider.notifier)
            .updateSavingsGoal(goal);
      }
      if (!mounted) return;
      AppFeedbackService.showSuccess(
        context,
        existingGoal == null
            ? l10n.savingsSavedSuccessfully
            : l10n.savingsUpdatedSuccessfully,
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.showError(
        context,
        l10n.savingsUnableToSave,
      );
    } finally {
      AppFeedbackService.dismissLoading();
    }
  }

  Future<void> _openContributionDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final appCurrency = ref.read(appCurrencyControllerProvider);
    final currencyFormat = CurrencyUtils.getFormat(appCurrency);
    final accounts = await ref.read(accountsListProvider.future);
    if (!context.mounted) return;
    final result = await showDialog<_ContributionResult>(
      context: context,
      builder: (_) => _ContributionDialog(
        goalTitle: goal.title,
        currencySymbol: CurrencyUtils.symbol(appCurrency),
        currencyFormat: currencyFormat,
        accounts: accounts,
      ),
    );

    if (result == null || result.amount <= 0 || !context.mounted) return;

    // Only the portion that actually lands in the goal (clamped to target)
    // should leave the source account, so cash-on-hand and savings stay in
    // sync. The transfer debits the chosen account but is excluded from the
    // income/expense chips and budget spending (both filter on those types).
    final newSaved =
        (goal.savedAmount + result.amount).clamp(0, goal.targetAmount).toDouble();
    final applied = newSaved - goal.savedAmount;
    if (applied <= 0) return;

    await ref.read(transactionListProvider().notifier).addTransaction(
          Transaction(
            id: const Uuid().v4(),
            accountId: result.accountId,
            amount: applied,
            currency: appCurrency,
            type: TransactionType.transfer,
            category: 'Savings',
            date: DateTime.now(),
            note: goal.id,
          ),
        );

    final updated = goal.copyWith(savedAmount: newSaved);
    await ref
        .read(savingsGoalListProvider.notifier)
        .updateSavingsGoal(updated);
    if (!context.mounted) return;
    AppFeedback.show(
      context,
      message: l10n.savingsProgressLine(
        ((updated.savedAmount / updated.targetAmount) * 100)
            .clamp(0, 100)
            .toStringAsFixed(1),
        currencyFormat.format(
          (updated.targetAmount - updated.savedAmount).clamp(
            0,
            double.infinity,
          ),
        ),
      ),
      type: AppFeedbackType.success,
    );
  }

  void _showSimulation(
    BuildContext context,
    SavingsGoal goal,
    double monthlyIncrease,
    NumberFormat currencyFormat,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final elapsedMonths =
        (((now.difference(goal.createdAt ?? now).inDays) / 30).clamp(1, 120))
            .toDouble();
    final currentRate =
        goal.savedAmount > 0 ? goal.savedAmount / elapsedMonths : 0;
    final newRate = currentRate + monthlyIncrease;
    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
      0,
      double.infinity,
    );
    final monthsToComplete = newRate > 0 ? (remaining / newRate).ceil() : null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.savingsScenarioSimulationTitle),
        content: Text(
          monthsToComplete == null
              ? l10n.savingsUnableEstimateCompletion
              : l10n.savingsScenarioEstimate(
                  currencyFormat.format(monthlyIncrease),
                  monthsToComplete,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  String _goalStatusLabel(
    AppLocalizations l10n,
    double progress,
    int projectedLate,
  ) {
    if (progress >= 1.0) return l10n.savingsStatusCompleted;
    if (projectedLate > 0) return l10n.savingsStatusBehindSchedule;
    if (progress >= 0.6) return l10n.savingsStatusOnPace;
    return l10n.savingsStatusBuildingMomentum;
  }

  Color _goalStatusColor(Brightness brightness, double progress, int projectedLate) {
    if (progress >= 1.0) return AppColors.statusFor(brightness, AppStatus.success);
    if (projectedLate > 0) return AppColors.statusFor(brightness, AppStatus.danger);
    if (progress >= 0.6) return AppColors.statusFor(brightness, AppStatus.warning);
    return AppColors.statusFor(brightness, AppStatus.info);
  }
}

/// Redesigned Savings Nudge Card
class _SavingsNudgeCard extends StatelessWidget {
  const _SavingsNudgeCard({required this.nudges});

  final List<SavingsNudge> nudges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final infoColor = AppColors.statusFor(brightness, AppStatus.info);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusTint(brightness, AppStatus.info),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: infoColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: infoColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: infoColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.savingsInsightsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...nudges.map((nudge) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getSeverityIcon(nudge.severity),
                    size: 16,
                    color: _getSeverityColor(brightness, nudge.severity),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nudge.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getSeverityIcon(SavingsNudgeSeverity severity) {
    return switch (severity) {
      SavingsNudgeSeverity.critical => Icons.error_outline,
      SavingsNudgeSeverity.warning => Icons.warning_amber_outlined,
      SavingsNudgeSeverity.info => Icons.info_outline,
    };
  }

  Color _getSeverityColor(Brightness brightness, SavingsNudgeSeverity severity) {
    return switch (severity) {
      SavingsNudgeSeverity.critical => AppColors.statusFor(brightness, AppStatus.danger),
      SavingsNudgeSeverity.warning => AppColors.statusFor(brightness, AppStatus.warning),
      SavingsNudgeSeverity.info => AppColors.statusFor(brightness, AppStatus.info),
    };
  }
}

/// Surplus allocation card
class _SavingsSurplusCard extends StatelessWidget {
  const _SavingsSurplusCard({
    required this.monthlySurplus,
    required this.currencyFormat,
    required this.onOpenAllocator,
  });

  final double monthlySurplus;
  final NumberFormat currencyFormat;
  final VoidCallback onOpenAllocator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final incomeColor = AppColors.income(brightness);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.incomeTint(brightness),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.savingsMonthlySurplusAvailable,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(monthlySurplus),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: incomeColor,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.savingsAllocateToHighestPriority,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenAllocator,
            icon: const Icon(Icons.auto_graph),
            label: Text(l10n.savingsSimulateCustomAllocation),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: incomeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Redesigned Savings Goal Card
class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.progress,
    required this.remaining,
    required this.statusColor,
    required this.statusLabel,
    required this.suggestedMonthly,
    required this.projectedLate,
    required this.monthsRemaining,
    required this.hasDeadline,
    required this.currencyFormat,
    required this.l10n,
    required this.onActionSelected,
  });

  final SavingsGoal goal;
  final double progress;
  final double remaining;
  final Color statusColor;
  final String statusLabel;
  final double suggestedMonthly;
  final int projectedLate;
  final int monthsRemaining;
  final bool hasDeadline;
  final NumberFormat currencyFormat;
  final AppLocalizations l10n;
  final ValueChanged<String> onActionSelected;

  // Savings fill ramp — more progress is good, so it greens up as it fills,
  // using the same shared status tokens as every other meter in the app.
  Color _milestoneProgressColor(double progress, Brightness brightness) {
    if (progress >= 0.75) {
      return AppColors.statusFor(brightness, AppStatus.success);
    }
    if (progress >= 0.50) {
      return AppColors.statusFor(brightness, AppStatus.warning);
    }
    return AppColors.statusFor(brightness, AppStatus.danger);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Goal title, status badge, and menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity( 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity( 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              AppActionMenu(
                title: goal.title,
                tooltip: l10n.savingsGoalActions,
                onSelected: onActionSelected,
                items: [
                  AppActionItem(
                    value: 'addFunds',
                    label: l10n.savingsAddFunds,
                    icon: Icons.add_circle_outline,
                  ),
                  AppActionItem(
                    value: 'simulate',
                    label: l10n.savingsSimulateContribution,
                    icon: Icons.auto_graph,
                  ),
                  AppActionItem(
                    value: 'setPriority',
                    label: l10n.savingsSetPriority,
                    icon: Icons.flag_outlined,
                  ),
                  AppActionItem(
                    value: 'edit',
                    label: l10n.savingsEditGoal,
                    icon: Icons.edit_outlined,
                  ),
                  AppActionItem(
                    value: 'pause',
                    label: l10n.savingsPauseAutoAllocation,
                    icon: Icons.pause_circle_outline,
                  ),
                  AppActionItem(
                    value: 'complete',
                    label: l10n.savingsMarkComplete,
                    icon: Icons.check_circle_outline,
                  ),
                  AppActionItem(
                    value: 'archive',
                    label: l10n.commonArchive,
                    icon: Icons.archive_outlined,
                  ),
                  AppActionItem(
                    value: 'delete',
                    label: l10n.savingsDeleteGoal,
                    icon: Icons.delete_outline,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount row: Saved / Target
          Text(
            '${currencyFormat.format(goal.savedAmount)} / ${currencyFormat.format(goal.targetAmount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity( 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                _milestoneProgressColor(progress, Theme.of(context).brightness),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text
          Text(
            '${(progress * 100).toStringAsFixed(1)}% complete • ${currencyFormat.format(remaining)} remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          // Deadline info
          if (hasDeadline) ...[
            const SizedBox(height: 12),
            Text(
              'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(goal.deadline!)} • $monthsRemaining months',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],

          const SizedBox(height: 12),

          // Suggestion text
          Text(
            'Suggested: ${currencyFormat.format(suggestedMonthly)}/month',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          if (projectedLate > 0)
            Text(
              l10n.savingsProjectedLateBy(projectedLate),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.statusFor(
                      Theme.of(context).brightness,
                      AppStatus.danger,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
            ),

          const SizedBox(height: 10),
          Text(
            l10n.savingsOverflowMenuHint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),

          // Achieved badge
          if (goal.savedAmount >= goal.targetAmount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusTint(
                  Theme.of(context).brightness,
                  AppStatus.success,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.statusFor(
                      Theme.of(context).brightness,
                      AppStatus.success,
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.savingsGoalAchieved,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.statusFor(
                              Theme.of(context).brightness,
                              AppStatus.success,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestonePopupEvent {
  const _MilestonePopupEvent({
    required this.title,
    required this.headline,
    required this.message,
  });

  final String title;
  final String headline;
  final String message;
}

class _SavingsDormantGoalCard extends StatelessWidget {
  const _SavingsDormantGoalCard({
    required this.goal,
    required this.currencyFormat,
    required this.statusLabel,
    required this.onRestore,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final NumberFormat currencyFormat;
  final String statusLabel;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$statusLabel • ${currencyFormat.format(goal.savedAmount)} / ${currencyFormat.format(goal.targetAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRestore,
            child: Text(l10n.commonResume),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SURPLUS SIMULATION FLOW
// ============================================================================

class _SurplusSimulationResult {
  const _SurplusSimulationResult({
    required this.amount,
    required this.confirmed,
  });

  final double amount;
  final bool confirmed;
}

enum _SimulationState {
  idle,
  simulated,
  confirmed,
  cancelled,
  error,
}

class _SurplusSimulationSheet extends StatefulWidget {
  const _SurplusSimulationSheet({
    required this.goals,
    required this.monthlySurplus,
    required this.currencyFormat,
    required this.currencyCode,
  });

  final List<SavingsGoal> goals;
  final double monthlySurplus;
  final NumberFormat currencyFormat;
  final String currencyCode;

  @override
  State<_SurplusSimulationSheet> createState() =>
      _SurplusSimulationSheetState();
}

class _SurplusSimulationSheetState extends State<_SurplusSimulationSheet> {
  final _controller = TextEditingController();
  _SimulationState _state = _SimulationState.idle;
  double? _simulatedAmount;
  String? _errorMessage;

  SavingsGoal get _topGoal {
    final sorted = [...widget.goals]..sort((a, b) {
        final aRemaining =
            (a.targetAmount - a.savedAmount).clamp(0, double.infinity);
        final bRemaining =
            (b.targetAmount - b.savedAmount).clamp(0, double.infinity);
        return aRemaining.compareTo(bRemaining);
      });
    return sorted.first;
  }

  void _setQuickAmount(double amount) {
    _controller.text = amount.toStringAsFixed(0);
  }

  Future<void> _simulate() async {
    final l10n = AppLocalizations.of(context)!;
    final parsed = FormValidation.parseDecimal(_controller.text);
    if (parsed == null || parsed <= 0) {
      setState(() {
        _state = _SimulationState.error;
        _errorMessage = l10n.savingsEnterAmountGreaterThanZero;
      });
      return;
    }

    if (parsed > widget.monthlySurplus) {
      final confirmOver = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmActionDialog(
              title: l10n.savingsUseMoreThanSurplusTitle,
              message: l10n.savingsAmountAboveSurplusWarning,
              confirmLabel: l10n.commonContinue,
            ),
          ) ??
          false;
      if (!confirmOver) return;
    }

    setState(() {
      _simulatedAmount = parsed;
      _state = _SimulationState.simulated;
      _errorMessage = null;
    });
  }

  void _apply() {
    final l10n = AppLocalizations.of(context)!;
    final amount = _simulatedAmount;
    if (amount == null || amount <= 0) {
      setState(() {
        _state = _SimulationState.error;
        _errorMessage = l10n.savingsRunSimulationFirst;
      });
      return;
    }
    setState(() => _state = _SimulationState.confirmed);
    Navigator.of(context).pop(
      _SurplusSimulationResult(amount: amount, confirmed: true),
    );
  }

  void _cancel() {
    setState(() => _state = _SimulationState.cancelled);
    final amount = _simulatedAmount ?? 0;
    Navigator.of(context).pop(
      _SurplusSimulationResult(amount: amount, confirmed: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topGoal = _topGoal;
    final amount = _simulatedAmount ?? 0;
    final remainingToGoal =
        (topGoal.targetAmount - topGoal.savedAmount).clamp(0, double.infinity);
    final projectedRemaining =
        (remainingToGoal - amount).clamp(0, double.infinity);
    final now = DateTime.now();
    final elapsedMonths =
        (((now.difference(topGoal.createdAt ?? now).inDays) / 30).clamp(1, 120))
            .toDouble();
    final currentMonthlyRate =
        topGoal.savedAmount <= 0 ? 0 : topGoal.savedAmount / elapsedMonths;
    final improvedRate = currentMonthlyRate + amount;
    final currentMonthsToComplete = currentMonthlyRate <= 0
        ? null
        : (remainingToGoal / currentMonthlyRate).ceil();
    final projectedMonthsToComplete =
        improvedRate <= 0 ? null : (remainingToGoal / improvedRate).ceil();
    final monthsSaved = currentMonthsToComplete == null ||
            projectedMonthsToComplete == null
        ? null
        : (currentMonthsToComplete - projectedMonthsToComplete).clamp(0, 240);

    final projectedCompletionDate = projectedMonthsToComplete == null
        ? null
        : DateTime(now.year, now.month + projectedMonthsToComplete, now.day);

    return AppFormSheet(
      maxHeightFactor: 0.85,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
              l10n.savingsMonthlySurplusSimulation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target goal: ${topGoal.title}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            CurrencyInput(
              controller: _controller,
              label: l10n.savingsCustomMonthlyAllocation,
              currencySymbol: widget.currencyFormat.currencySymbol,
              helperText:
                  'Available surplus: ${widget.currencyFormat.format(widget.monthlySurplus)}',
              decimalDigits: MoneyUtils.decimalDigits(widget.currencyCode),
              validator: null,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('25%'),
                  onPressed: () =>
                      _setQuickAmount(widget.monthlySurplus * 0.25),
                ),
                ActionChip(
                  label: const Text('50%'),
                  onPressed: () => _setQuickAmount(widget.monthlySurplus * 0.5),
                ),
                ActionChip(
                  label: const Text('100%'),
                  onPressed: () => _setQuickAmount(widget.monthlySurplus),
                ),
              ],
            ),
            if (_state == _SimulationState.error && _errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_state == _SimulationState.simulated ||
                _state == _SimulationState.confirmed ||
                _state == _SimulationState.cancelled) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity( 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.savingsSimulationOutput,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text(
                        'Monthly impact: ${widget.currencyFormat.format(amount)}'),
                    Text(
                        'Remaining after allocation: ${widget.currencyFormat.format((widget.monthlySurplus - amount).clamp(-double.infinity, double.infinity))}'),
                    Text(
                        'Goal remaining after allocation: ${widget.currencyFormat.format(projectedRemaining)}'),
                    Text(
                      projectedCompletionDate == null
                          ? 'Projected completion date: unavailable'
                          : 'Projected completion date: ${MaterialLocalizations.of(context).formatMediumDate(projectedCompletionDate)}',
                    ),
                    Text(
                      monthsSaved == null
                          ? 'Months saved: unavailable'
                          : 'Months saved: $monthsSaved',
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: _simulate,
            child: Text(l10n.savingsSimulate),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _state == _SimulationState.simulated ? _apply : null,
            child: Text(l10n.savingsConfirmAndApply),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancel,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// FORM AND HELPER DATA STRUCTURES
// ============================================================================

class _SavingsGoalFormResult {
  const _SavingsGoalFormResult({
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.priority,
    required this.autoAllocate,
    required this.deadline,
  });

  final String title;
  final double targetAmount;
  final double savedAmount;
  final GoalPriority priority;
  final bool autoAllocate;
  final DateTime? deadline;
}

class _SavingsGoalFormSheet extends StatefulWidget {
  const _SavingsGoalFormSheet({
    this.existingGoal,
    required this.currencySymbol,
    required this.currencyCode,
  });

  final SavingsGoal? existingGoal;
  final String currencySymbol;
  final String currencyCode;

  @override
  State<_SavingsGoalFormSheet> createState() => _SavingsGoalFormSheetState();
}

class _SavingsGoalFormSheetState extends State<_SavingsGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late GoalPriority _priority;
  late bool _autoAllocate;
  late DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingGoal?.title ?? '',
    );
    _targetController = TextEditingController(
      text: widget.existingGoal?.targetAmount.toStringAsFixed(2) ?? '',
    );
    _savedController = TextEditingController(
      text: widget.existingGoal?.savedAmount.toStringAsFixed(2) ?? '0',
    );
    _priority = widget.existingGoal?.priority ?? GoalPriority.medium;
    _autoAllocate = widget.existingGoal?.autoAllocate ?? false;
    _deadline = widget.existingGoal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (!mounted || picked == null) return;
    setState(() => _deadline = picked);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedbackService.showWarning(
        context,
        l10n.savingsCompleteRequiredFields,
      );
      return;
    }
    final targetAmount =
        FormValidation.parseDecimal(_targetController.text.trim()) ?? 0;
    if (targetAmount <= 0) {
      AppFeedbackService.showWarning(
        context,
        l10n.savingsTargetAmountMustBeGreaterThanZero,
      );
      return;
    }
    final savedRaw =
        FormValidation.parseDecimal(_savedController.text.trim()) ?? 0;
    final savedAmount = savedRaw.clamp(0.0, targetAmount);
    Navigator.of(context).pop(
      _SavingsGoalFormResult(
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        priority: _priority,
        autoAllocate: _autoAllocate,
        deadline: _deadline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.existingGoal != null;
    final liveTarget =
        FormValidation.parseDecimal(_targetController.text.trim()) ?? 0;
    final liveSaved =
        FormValidation.parseDecimal(_savedController.text.trim()) ?? 0;
    final liveTitle = _titleController.text.trim();
    final liveProgress = liveTarget > 0
        ? (liveSaved / liveTarget).clamp(0.0, 1.0)
        : 0.0;

    final formFields = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity( 0.10)
                    : Colors.black.withOpacity( 0.10),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: liveProgress.toDouble(),
                        strokeWidth: 3,
                        backgroundColor:
                            colorScheme.primary.withOpacity( 0.12),
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.flag_rounded,
                        color: colorScheme.primary, size: 18),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? l10n.savingsEditGoal : l10n.savingsCreateGoal,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveTitle.isNotEmpty
                            ? liveTarget > 0
                                ? '$liveTitle · ${widget.currencySymbol} ${liveTarget.toStringAsFixed(2)}'
                                : liveTitle
                            : l10n.savingsNameGoalAndSetTarget,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ModernInput(
            controller: _titleController,
            label: l10n.savingsGoalName,
            helperText: l10n.savingsChooseSpecificTarget,
            onChanged: (_) => setState(() {}),
            validator: (value) =>
                FormValidation.requiredText(value, l10n.savingsEnterGoalName),
          ),
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _targetController,
            label: l10n.savingsTargetAmount,
            currencySymbol: widget.currencySymbol,
            decimalDigits: MoneyUtils.decimalDigits(widget.currencyCode),
            onChanged: (_) => setState(() {}),
            validator: (value) => FormValidation.positiveAmount(
              value,
              l10n.savingsEnterValidTargetAmount,
              l10n.savingsEnterValidTargetAmount,
            ),
          ),
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _savedController,
            label: l10n.savingsCurrentSavedAmount,
            currencySymbol: widget.currencySymbol,
            decimalDigits: MoneyUtils.decimalDigits(widget.currencyCode),
            onChanged: (_) => setState(() {}),
            validator: (value) => FormValidation.nonNegativeAmount(
              value,
              l10n.savingsEnterValidSavedAmount,
            ),
          ),
          const SizedBox(height: 16),
          // ── Priority chips ──
          _GoalPriorityChipSelector(
            value: _priority,
            l10n: l10n,
            onChanged: (p) => setState(() => _priority = p),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _autoAllocate,
            title: Text(l10n.savingsEnableAutoAllocation),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _autoAllocate = value),
          ),
          const SizedBox(height: 16),
          ModernDatePicker(
            label: l10n.savingsDeadlineOptional,
            value: _deadline == null
                ? l10n.savingsNoDeadline
                : MaterialLocalizations.of(context)
                    .formatMediumDate(_deadline!),
            trailing: _deadline == null
                ? null
                : IconButton(
                    tooltip: l10n.a11yClearDeadline,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _deadline = null),
                  ),
            onTap: _pickDeadline,
          ),
          const SizedBox(height: InputStyles.fieldSpacing),
        ],
      ),
    );

    return AppFormSheet(
      onClose: () => Navigator.of(context).pop(),
      maxHeightFactor: 0.90,
      body: formFields,
      actions: FilledButton.icon(
        onPressed: _submit,
        icon: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded),
        label: Text(isEdit ? l10n.savingsUpdateGoal : l10n.savingsSaveGoal),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}

/// Result of the add-funds dialog: how much to contribute and which account
/// the cash leaves from.
class _ContributionResult {
  const _ContributionResult({required this.amount, required this.accountId});

  final double amount;
  final String accountId;
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({
    required this.goalTitle,
    required this.currencySymbol,
    required this.currencyFormat,
    required this.accounts,
  });

  final String goalTitle;
  final String currencySymbol;
  final NumberFormat currencyFormat;
  final List<Account> accounts;

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  late final TextEditingController _controller;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _accountId =
        widget.accounts.isNotEmpty ? widget.accounts.first.id : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim()) ?? 0;
    final accountId = _accountId;
    if (value <= 0 || accountId == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      _ContributionResult(amount: value, accountId: accountId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.savingsAddToGoal(widget.goalTitle)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: InputStyles.inputTextStyle(Theme.of(context)),
            decoration: InputDecoration(
              labelText: l10n.amount,
              prefixText: '${widget.currencySymbol} ',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.accounts.isNotEmpty && _accountId != null) ...[
            const SizedBox(height: 16),
            AppSelectField<String>(
              value: _accountId!,
              label: l10n.savingsFromAccount,
              prefixIcon: Icons.account_balance_wallet_outlined,
              onChanged: (v) => setState(() => _accountId = v),
              options: widget.accounts
                  .map(
                    (a) => AppDropdownOption<String>(
                      value: a.id,
                      label:
                          '${a.name}  ·  ${widget.currencyFormat.format(a.currentBalance)}',
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}

// ─── Goal priority chip selector ────────────────────────────────────────────

class _GoalPriorityChipSelector extends StatelessWidget {
  const _GoalPriorityChipSelector({
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  final GoalPriority value;
  final AppLocalizations l10n;
  final ValueChanged<GoalPriority> onChanged;

  // Shared priority ramp: low → success, medium → info, high → warning,
  // critical → danger. Identical mapping to subscription importance so the two
  // concepts read the same everywhere.
  static Color _color(GoalPriority p, Brightness b) => switch (p) {
        GoalPriority.low => AppColors.statusFor(b, AppStatus.success),
        GoalPriority.medium => AppColors.statusFor(b, AppStatus.info),
        GoalPriority.high => AppColors.statusFor(b, AppStatus.warning),
        GoalPriority.critical => AppColors.statusFor(b, AppStatus.danger),
      };

  static String _shortLabel(AppLocalizations l10n, GoalPriority p) => switch (p) {
        GoalPriority.low => l10n.savingsPriorityShortLow,
        GoalPriority.medium => l10n.savingsPriorityShortMedium,
        GoalPriority.high => l10n.savingsPriorityShortHigh,
        GoalPriority.critical => l10n.savingsPriorityShortCritical,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.savingsPriority,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: GoalPriority.values.map((p) {
            final selected = value == p;
            final color = _color(p, Theme.of(context).brightness);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity( 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : scheme.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                color: selected
                                    ? color
                                    : scheme.onSurfaceVariant,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                          child: Text(
                            _shortLabel(l10n, p),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
