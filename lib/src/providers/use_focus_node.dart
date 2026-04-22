import '../framework.dart';

extension ContextUseFocusNode on BuildContext {
  /// Creates a [FocusNode] that is automatically disposed.
  FocusNode useFocusNode({
    String? debugLabel,
    FocusOnKeyEventCallback? onKeyEvent,
    bool skipTraversal = false,
    bool canRequestFocus = true,
    bool descendantsAreFocusable = true,
    bool descendantsAreTraversable = true,
    Object? key,
  }) {
    return bind(
      _UseFocusNode(
        debugLabel: debugLabel,
        onKeyEvent: onKeyEvent,
        skipTraversal: skipTraversal,
        canRequestFocus: canRequestFocus,
        descendantsAreFocusable: descendantsAreFocusable,
        descendantsAreTraversable: descendantsAreTraversable,
        key: key,
      ),
    );
  }
}

class _UseFocusNode extends HookProvider<FocusNode> {
  const _UseFocusNode({
    this.debugLabel,
    this.onKeyEvent,
    required this.skipTraversal,
    required this.canRequestFocus,
    required this.descendantsAreFocusable,
    required this.descendantsAreTraversable,
    super.key,
  });

  final String? debugLabel;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool skipTraversal;
  final bool canRequestFocus;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  @override
  _UseFocusNodeState createState() => _UseFocusNodeState();
}

class _UseFocusNodeState extends HookState<FocusNode, _UseFocusNode> {
  @override
  String get debugLabel => 'useFocusNode';

  late final node = FocusNode(
    debugLabel: provider.debugLabel,
    onKeyEvent: provider.onKeyEvent,
    skipTraversal: provider.skipTraversal,
    canRequestFocus: provider.canRequestFocus,
    descendantsAreFocusable: provider.descendantsAreFocusable,
    descendantsAreTraversable: provider.descendantsAreTraversable,
  );

  @override
  void didUpdateProvider(_UseFocusNode oldProvider) {
    super.didUpdateProvider(oldProvider);
    if (provider.onKeyEvent != oldProvider.onKeyEvent) {
      node.onKeyEvent = provider.onKeyEvent;
    }
    if (provider.skipTraversal != oldProvider.skipTraversal) {
      node.skipTraversal = provider.skipTraversal;
    }
    if (provider.canRequestFocus != oldProvider.canRequestFocus) {
      node.canRequestFocus = provider.canRequestFocus;
    }
    if (provider.descendantsAreFocusable !=
        oldProvider.descendantsAreFocusable) {
      node.descendantsAreFocusable = provider.descendantsAreFocusable;
    }
    if (provider.descendantsAreTraversable !=
        oldProvider.descendantsAreTraversable) {
      node.descendantsAreTraversable = provider.descendantsAreTraversable;
    }
  }

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  FocusNode build(BuildContext context) {
    return node;
  }
}
