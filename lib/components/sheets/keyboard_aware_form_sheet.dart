import 'package:flutter/material.dart';
import 'package:smartbudget/components/sheets/app_sheet_container.dart';

class KeyboardAwareFormSheet extends StatefulWidget {
  const KeyboardAwareFormSheet({
    super.key,
    required this.body,
    this.actions,
    this.onClose,
    this.maxHeightFactor = 0.78,
    this.bodyPadding = const EdgeInsets.fromLTRB(24, 12, 24, 12),
    this.scrollController,
    this.showDragHandle = true,
    this.dismissOnBarrierTap = false,
  });

  final Widget body;
  final Widget? actions;
  final VoidCallback? onClose;
  final double maxHeightFactor;
  final EdgeInsetsGeometry bodyPadding;
  final ScrollController? scrollController;
  final bool showDragHandle;
  final bool dismissOnBarrierTap;

  @override
  State<KeyboardAwareFormSheet> createState() => _KeyboardAwareFormSheetState();
}

class _KeyboardAwareFormSheetState extends State<KeyboardAwareFormSheet> {
  ScrollController? _ownedScrollController;

  ScrollController get _scrollController {
    return widget.scrollController ?? _ownedScrollController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
    FocusManager.instance.addListener(_ensureFocusedFieldVisible);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_ensureFocusedFieldVisible);
    _ownedScrollController?.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _ensureFocusedFieldVisible() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (mounted) {
      setState(() {});
    }
    if (focusedContext == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final renderObject = focusedContext.findRenderObject();
      if (renderObject == null || !renderObject.attached) {
        return;
      }
      Scrollable.ensureVisible(
        focusedContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.18,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewportHeight = mediaQuery.size.height;
    // Height taken up by the on-screen keyboard (0 when hidden). The sheet must
    // sit above it and be constrained to the remaining visible area, otherwise
    // the lower fields and the action button end up hidden behind the keyboard.
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final maxHeight = (viewportHeight - keyboardInset) * widget.maxHeightFactor;
    final resolvedBodyPadding =
        widget.bodyPadding.resolve(Directionality.of(context));
    final bodyBottomInset = widget.actions != null ? 24.0 : 12.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: Stack(
        children: [
          if (widget.dismissOnBarrierTap)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _dismissKeyboard();
                  widget.onClose?.call();
                },
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SizedBox(
                  width: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismissKeyboard,
                  child: AppSheetContainer(
                    padding: EdgeInsets.zero,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.showDragHandle)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          Flexible(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: resolvedBodyPadding.copyWith(
                                bottom: resolvedBodyPadding.bottom +
                                    bodyBottomInset,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  widget.body,
                                  if (widget.actions != null) ...[
                                    const SizedBox(height: 16),
                                    widget.actions!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
