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
}

extension on ProvideItRootElement {
  void _assert(BuildContext context, String method) {
    assert(
      context is Element && context.debugDoingBuild,
      '$method() should be called within the build() method of a widget.',
    );
  }
}
