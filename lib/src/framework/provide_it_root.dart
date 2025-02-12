part of '../framework.dart';

class ProvideItRoot extends InheritedWidget {
  const ProvideItRoot({super.key, required super.child});

  static ProvideItRootElement of(BuildContext context) {
    final el = context.getElementForInheritedWidgetOfExactType<ProvideItRoot>();
    assert(el != null, 'You must set `ProvideIt.root` in your app.');
    return el! as ProvideItRootElement;
  }

  @override
  InheritedElement createElement() => ProvideItRootElement(this);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class ProvideItRootElement extends InheritedElement {
  ProvideItRootElement(super.widget);
  bool _reassembled = false;
  bool _doingInit = false;

  bool get debugDoingInit => _doingInit;

  // state tree
  final _tree = TreeMap<Element, TreeMap<int, _State>>();
  final _index = <Element, int>{};

  // state cache
  final _cache = <BuildContext, Map<Type, Map<Object?, _State?>>>{};

  int _initIndex(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // we reset the index for the next build.
      final index = _index.remove(context) ?? 0;
      final length = _tree[context]?.length ?? 0;

      // if a ref was removed, we dispose it.
      if (index < length) _disposeIndex(context, index);
      _reassembled = false;
    });

    return 0;
  }

  _State<T> _state<T>(BuildContext context, Ref<T> ref) {
    assert(context is Element);
    assert(
      context.debugDoingBuild,
      'build() should be called within the build method of a widget.',
    );

    // we depend so we can get notified by [removeDependent].
    context.dependOnInheritedElement(this);

    final branch = _tree[context as Element] ??= TreeMap<int, _State>();
    final index = _index[context] ??= _initIndex(context);
    _index[context] = index + 1;

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
      _disposeIndex(context, index);

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
    final contextCache = _cache[context] ??= {};
    final typeCache = contextCache[T] ??= HashMap(equals: Ref.equals);
    final state = typeCache[key] ??= _findState<T>(key: key);

    if (state case _State<T> state) return state;
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
    return _state(context, ref).build(context) as R;
  }

  T read<T>(BuildContext context, {Object? key}) {
    return _stateOf<T>(context, key: key).read(context);
  }

  T watch<T>(BuildContext context, {Object? key}) {
    return _stateOf<T>(context, key: key).watch(context);
  }

  R select<T, R>(BuildContext context, R selector(T value), {Object? key}) {
    return _stateOf<T>(context, key: key).select(context, selector);
  }

  void listen<T>(BuildContext context, void listener(T value), {Object? key}) {
    _stateOf<T>(context, key: key).listen(context, listener);
  }

  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next), {
    Object? key,
  }) {
    _stateOf<T>(context, key: key).listenSelect(context, selector, listener);
  }

  @override
  void reassemble() {
    super.reassemble();
    _reassembled = true;
    for (final branch in _tree.values) {
      for (final state in branch.values) {
        state.reassemble();
      }
    }
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
      // if it's still mounted, we reactivate the providers.
      dependent.mounted
          ? _tree[dependent]?.forEach((_, it) => it.activate())
          : _disposeDependents(dependent);
    });
    super.removeDependent(dependent);
  }

  /// Called when any [Ref] is removed from this [context].
  void _disposeIndex(BuildContext context, int index) {
    final branch = _tree[context] ?? TreeMap<int, _State>();
    final indexes = branch.keys.where((i) => i >= index);

    // we dispose current index and subsequents as they are displaced.
    for (var index in indexes) {
      branch.remove(index)?.dispose();
    }
  }

  /// Called when a [context] is removed from the tree.
  void _disposeDependents(BuildContext context) {
    _tree.remove(context)?.forEach((_, state) => state.dispose());
    _index.remove(context);
    _cache.remove(context);
  }
}
