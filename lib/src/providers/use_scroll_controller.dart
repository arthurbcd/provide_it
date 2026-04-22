import '../framework.dart';

extension ContextUseScrollController on BuildContext {
  /// Creates a [ScrollController] that is automatically disposed.
  ScrollController useScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
    ScrollControllerCallback? onAttach,
    ScrollControllerCallback? onDetach,
    Object? key,
  }) {
    return bind(
      _UseScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
        onAttach: onAttach,
        onDetach: onDetach,
        key: key,
      ),
    );
  }
}

class _UseScrollController extends HookProvider<ScrollController> {
  const _UseScrollController({
    required this.initialScrollOffset,
    required this.keepScrollOffset,
    this.debugLabel,
    this.onAttach,
    this.onDetach,
    super.key,
  });

  final double initialScrollOffset;
  final bool keepScrollOffset;
  final String? debugLabel;
  final ScrollControllerCallback? onAttach;
  final ScrollControllerCallback? onDetach;

  @override
  _UseScrollControllerState createState() => _UseScrollControllerState();
}

class _UseScrollControllerState
    extends HookState<ScrollController, _UseScrollController> {
  @override
  String get debugLabel => 'useScrollController';

  late final controller = ScrollController(
    initialScrollOffset: provider.initialScrollOffset,
    keepScrollOffset: provider.keepScrollOffset,
    debugLabel: provider.debugLabel,
    onAttach: provider.onAttach,
    onDetach: provider.onDetach,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  ScrollController build(BuildContext context) {
    return controller;
  }
}
