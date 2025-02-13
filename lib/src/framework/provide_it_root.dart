part of 'framework.dart';

class ProvideItRoot extends InheritedWidget {
  const ProvideItRoot({super.key, required super.child});

  @override
  InheritedElement createElement() => ProvideItRootElement(this);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class ProvideItRootElement extends InheritedElement {
  ProvideItRootElement._(super.widget);
  bool _reassembled = false;
  bool _doingInit = false;

  factory ProvideItRootElement(ProvideItRoot widget) {
    assert(_instance == null, 'You can only have one `ProvideIt.root`.');
    return _instance ??= ProvideItRootElement._(widget);
  }

  static ProvideItRootElement? _instance;
  static ProvideItRootElement get instance {
    assert(_instance != null, 'You must set `ProvideIt.root` in your app.');
    return _instance!;
  }

  bool get debugDoingInit => _doingInit;

  // state binder tree by context and index.
  final _tree = TreeMap<Element, TreeMap<int, _State>>();
  final _treeIndex = <Element, int>{};

  // state finder cache by context, type and key.
  final _cache = <BuildContext, Map<Type, Map<Object?, _State?>>>{};
  final _cacheIndex = <BuildContext, int>{};

  void _assert(BuildContext context, String method) {
    assert(
      context is Element && context.debugDoingBuild,
      '$method() should be called within the build() method of a widget.',
    );
  }

  int _initIndex(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      _treeIndex.remove(context);
      _cacheIndex.remove(context);
      _reassembled = false;
    });

    return 0;
  }

  _State<T> _state<T>(BuildContext context, Ref<T> ref) {
    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);

    final branch = _tree[context as Element] ??= TreeMap<int, _State>();
    final index = _treeIndex[context] ??= _initIndex(context);
    _treeIndex[context] = index + 1;

    _State<T> create() {
      _doingInit = true;

      final state = branch[index] = ref.createState()
        .._element = context
        .._ref = ref
        ..initState();

      _doingInit = false;

      return state;
    }

    _State<T> update(_State<T> old) {
      return old
        .._ref = ref
        ..didUpdateRef(old.ref);
    }

    _State<T> reset(_State<dynamic> old) {
      if (_reassembled) return create();
      throw StateError('${old.ref.runtimeType} != ${ref.runtimeType}');
    }

    return switch (branch[index]) {
      var old? when old.ref.runtimeType != ref.runtimeType => reset(old),
      _State<T> old when Ref.canUpdate(old.ref, ref) => update(old),
      _ => create(),
    };
  }

  _State<T> _stateOf<T>(BuildContext context, {Object? key}) {
    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);

    final contextCache = _cache[context] ??= {};
    final typeCache = contextCache[T] ??= HashMap(equals: Ref.equals);
    final state = typeCache[key] ??= _findState<T>(key: key);

    if (state case _State<T> state) {
      final index = _cacheIndex[context] ??= _initIndex(context as Element);
      _cacheIndex[context] = index + 1;

      return state;
    }

    // we assume it's a global lazy ref, so we can bind/read it.
    if (key case Ref<T> ref) return _state(context, ref);

    throw StateError('No state found for $T with key $key');
  }

  _State<T>? _findState<T>({Object? key}) {
    for (var branch in _tree.values) {
      for (var leaf in branch.values) {
        if (leaf case _State<T> state) {
          if (Ref.equals(state.key, key)) return state;
        }
      }
    }
    return null;
  }

  R bind<R, T>(BuildContext context, Ref<T> ref) {
    _assert(context, 'bind');

    return _state(context, ref).build(context) as R;
  }

  T watch<T>(BuildContext context, {Object? key}) {
    _assert(context, 'watch');

    return _stateOf<T>(context, key: key).watch(context);
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    _assert(context, 'select');

    final state = _stateOf<T>(context, key: key);
    return state.select(context, _cacheIndex[context]!, selector);
  }

  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    _assert(context, 'listen');

    final state = _stateOf<T>(context, key: key);
    state.listen(context, _cacheIndex[context]!, listener);
  }

  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    _assert(context, 'listenSelect');

    final state = _stateOf<T>(context, key: key);
    state.listenSelect(context, _cacheIndex[context]!, selector, listener);
  }

  T read<T>(BuildContext context, {Object? key}) {
    final state = _stateOf<T>(context, key: key);

    return state._lastReadValue = state.read(context);
  }

  T readIt<T>({Object? key}) => read<T>(this, key: key);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // we need to check if the dependent is still mounted
      // because it could have been removed from the tree.
      // if it's still mounted, we reactivate.
      dependent.mounted
          ? _tree[dependent]?.forEach((_, state) => state.activate())
          : _disposeDependent(dependent);
    });
    super.removeDependent(dependent);
  }

  /// Called when a [context] is unmounted from the tree.
  void _disposeDependent(Element context) {
    // we dispose all bindings of this context.
    _tree.remove(context)?.forEach((_, state) => state.dispose());
    _treeIndex.remove(context);
    _cacheIndex.remove(context);

    // we remove all dependencies of this context.
    _cache.remove(context)?.forEach((_, branch) =>
        branch.forEach((_, state) => state?.removeDependent(context)));
  }

  /// Called when a [ref] self-disposes on reassemble.
  void _disposeRef<T>(BuildContext context, Ref<T> ref) {
    final branch = _tree[context] ?? TreeMap<int, _State>();

    for (var e in branch.entries.toList()) {
      if (e.value.ref == ref) return branch.remove(e.key)?.dispose();
    }
  }

  void debugTree() {
    if (kDebugMode) {
      print(_tree);
    }
  }
}
