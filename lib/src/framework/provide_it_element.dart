part of '../framework.dart';

class ProvideItElement extends InheritedElement {
  @override
  ProvideIt get widget => super.widget as ProvideIt;

  factory ProvideItElement(ProvideIt widget) {
    assert(_instance == null, 'You can only have one `ProvideIt`.');
    return _instance ??= ProvideItElement._(widget);
  }
  static ProvideItElement? _instance;
  static ProvideItElement get instance {
    assert(_instance != null, 'You must set `ProvideIt` in your app.');
    return _instance!;
  }

  ProvideItElement._(super.widget) {
    Injector.defaultLocator = _defaultLocator(widget);
  }

  ParamLocator _defaultLocator(ProvideIt widget) {
    return (param) {
      if (param is NamedParam) {
        return widget.namedLocator?.call(param) ?? readIt(type: param.type);
      }
      return readIt(type: param.type);
    };
  }

  bool _reassembled = false;
  bool _doingInit = false;
  bool get debugDoingInit => _doingInit;

  // state binder tree by context and index.
  final _tree = TreeMap<Element, TreeMap<int, _State>>();
  final _treeIndex = <Element, int>{};

  // state reader cache by context, type and key.
  final _cache = <BuildContext, Map<String, Map<Object?, _State?>>>{};
  final _cacheIndex = <BuildContext, int>{};

  Future<void> allReady() {
    final futures = _tree.values
        .expand((branch) => branch.values.whereType<ProvideRefState>())
        .map((state) => state.future);

    return Future.wait(futures.nonNulls);
  }

  R bind<R, T>(BuildContext context, Ref<T> ref) {
    _assertContext(context, 'bind');

    return _state(context, ref).bind(context) as R;
  }

  T watch<T>(BuildContext context, {Object? key}) {
    _assertContext(context, 'watch');

    final state = _stateOf<T?>(context, key: key);
    final value = state?.watch(context);

    if (value is T) return value;
    throw StateError('watch<$T> not found, key: $key');
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    _assertContext(context, 'select');

    final state = _stateOf<T>(context, key: key);
    final value = state?.select(context, _cacheIndex[context]!, selector);

    if (value is R) return value;
    throw StateError('Ref<$T> not found, key: $key');
  }

  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    _assertContext(context, 'listen');

    final state = _stateOf<T>(context, key: key);
    _assertState<T>(state, 'listen', key);

    state?.listen(context, _cacheIndex[context]!, listener);
  }

  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    _assertContext(context, 'listenSelect');

    final state = _stateOf<T>(context, key: key);
    final index = _cacheIndex[context]!;
    _assertState<T>(state, 'listenSelect', key);

    state?.listenSelect<T, R>(context, index, selector, listener);
  }

  Future<void> reload<T>(BuildContext context, {Object? key}) async {
    final type = T.type;
    final state = _findState<AsyncRefState>(context, type, key);
    state?.load();
  }

  T read<T>(BuildContext context, {Object? key}) {
    final state = _stateOf<T>(context, key: key);
    final value = state?.of(context, listen: false);

    if (value is T) return value;
    throw StateError('Ref<$T> not found, key: $key');
  }

  T readIt<T>({String? type, Object? key}) {
    final state = _stateOf<T>(this, type: type, key: key);
    final value = state?.of(this, listen: false);

    if (value is T) return value;
    throw StateError('Ref<$T> not found, key: $key');
  }

  @override
  void reassemble() {
    for (final branch in _tree.values) {
      for (final state in branch.values) {
        state.reassemble();
      }
    }
    super.reassemble();
    _reassembled = true;
  }

  @override
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    super.notifyDependent(oldWidget, dependent);
    _tree[dependent]?.forEach((_, state) => state.didChangeDependencies());
  }

  @override
  void removeDependent(Element dependent) {
    _tree[dependent]?.forEach((_, state) => state.deactivate());

    void dispose() {
      _disposeBinds(dependent);
      _disposeCache(dependent);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been removed from the tree.
      // if it's still mounted, we reactivate.
      dependent.mounted
          ? _tree[dependent]?.forEach((_, state) => state.activate())
          : dispose();
    });
    super.removeDependent(dependent);
  }

  void debugTree() {
    if (kDebugMode) {
      print(_tree);
    }
  }

  @override
  Widget build() {
    final snapshot = future(() async => [
          Future(() => widget.provide?.call(this)),
          allReady(),
        ]);
    final isLoading = snapshot.connectionState == ConnectionState.waiting;
    print("isLoading $isLoading");

    return switch ((isLoading, snapshot.error, snapshot.stackTrace)) {
      (_, var e?, var s?) => widget.errorBuilder(this, e, s),
      (true, _, _) => widget.loadingBuilder(this),
      _ => super.build(),
    };
  }
}

extension on ProvideItElement {
  void _assertContext(BuildContext context, String method) {
    assert(
      context is Element && context.debugDoingBuild,
      '$method() should be called within the build() method of a widget.',
    );
  }

  void _assertState<T>(_State? state, String method, Object? key) {
    assert(
      state != null,
      'Failed to $method(). Ref<$T> not found, key: $key.',
    );
  }
}
