part of '../framework.dart';

class ProvideItScope implements ReadIt {
  static ProvideItScope of(BuildContext context) {
    return ProvideItElement.of(context).scope;
  }

  /// The attached [ProvideIt] element.
  ProvideItElement? _element;

  /// The watchers to use. Including [ProvideIt.additionalWatchers].
  List<Watcher> get watchers => {
        ...ProvideIt.defaultWatchers,
        ...?_element?.widget.additionalWatchers,
      }.toList();

  @protected
  T watch<T>(BuildContext context) {
    final bind = _bindOf<T>(context);
    final value = bind?.value;
    bind?.watch(context);

    if (value == null && null is T) return value;
    if (bind != null) return bind.read();

    throw StateError('Ref<$T> not found.');
  }

  @protected
  R select<T, R>(BuildContext context, R selector(T value)) {
    final bind = _bindOf<T>(context);
    final value = bind?.select<T, R>(context, selector);

    return value as R;
  }

  @protected
  void listen<T>(BuildContext context, void listener(T value)) {
    final bind = _bindOf<T>(context);

    bind?.listen<T>(context, listener);
  }

  @protected
  void listenSelect<T, R>(
    BuildContext context,
    R selector(T value),
    void listener(R previous, R next),
  ) {
    final bind = _bindOf<T>(context);

    bind?.listenSelect<T, R>(context, selector, listener);
  }

  @override
  bool get mounted => _element != null;

  // bind tree by context and index.
  // manages the lifecycle of the binds.
  late final _binds = TreeMap<Element, TreeMap<int, Bind>>()._assert(this);
  late final _bindIndex = <Element, int>{}._assert(this);

  // bind tree cache.
  // used to find the bind by type.
  late final _bindCache = <String, Set<Bind>>{}._assert(this);
  late final _scopedBindCache = <(String, BuildContext), Bind>{}._assert(this);

  // bind observers by the dependent `context`.
  // manages which observers can be notified.
  late final _observers = <Element, Set<Bind>>{}._assert(this);
  late final _observerIndex = <Element, int>{}._assert(this);

  /// Iterates over all [Ref] binds. Depth-first.
  Iterable<Bind> get binds sync* {
    for (var branch in _binds.values) {
      for (var bind in branch.values) {
        if (!bind.deactivated) yield bind;
      }
    }
  }

  void _register(Bind bind) {
    if (bind is! Scope) return;

    final binds = _bindCache[bind.type] ??= {};
    binds.add(bind);
  }

  void _unregister(Bind bind) {
    if (bind is! Scope) return;

    _bindCache[bind.type]!.remove(bind);
    for (var context in bind._scopedDependents) {
      _scopedBindCache.remove((bind.type, context));
    }
  }

  @protected
  Injector<I> injector<I>(Function create) {
    return _element?.injector<I>(create) ?? Injector<I>(create);
  }

  /// The future of [AsyncBind.isReady].
  @override
  FutureOr<void> allReady() {
    final futures = <Future>{};

    for (var bind in binds) {
      if (bind is! AsyncBind) continue;
      if (bind.isReady() case Future it) {
        futures.add(it.onError((e, s) {
          Error.throwWithStackTrace(
            '#${bind.index} ${bind.type} $e',
            s,
          );
        }));
      }
    }
    if (futures.isEmpty) return null;

    return Future.wait(futures, eagerError: true) as Future<void>;
  }

  /// The future when a [AsyncBind.isReady] is completed.
  @override
  FutureOr<void> isReady<T>({String? type, Object? key}) {
    type ??= T.type;

    final binds = switch (key) {
      null => _bindCache[type] ?? {},
      _ => _bindCache[type]?.where((it) => it.key == key) ?? {},
    };

    assert(binds.isNotEmpty, 'provide<$type> not found, key: $key.');
    assert(
      binds.length == 1 || binds.where((it) => !it.deactivated).length == 1,
      'Duplicate provide<$type>, key: $key.',
    );

    if (binds.lastOrNull case AsyncBind bind) return bind.isReady();
    return null;
  }

  @protected
  Bind<T, Ref<T>> bind<T>(BuildContext context, Ref<T> ref) {
    return _bind<T>(context as Element, ref);
  }

  @protected
  Bind? bindOf<T>(BuildContext context) {
    return _bindOf<T>(context);
  }

  Future<void> reload<T>() async {
    final bind = getBindOfType<T>();
    assert(bind is AsyncBind || null is T, 'AsyncRef<$T> not found.');

    await (bind as AsyncBind?)?.load();
  }

  @override
  T read<T>([BuildContext? context]) {
    final bind = getBindOfType<T>(context: context);
    final value = bind?.value;

    if (value == null && null is T) return value;
    if (bind != null) return bind.read();

    throw MissingProvideException('$T not found.');
  }

  @override
  FutureOr<T> readAsync<T>({String? type}) {
    type ??= T.type;

    final bind = getBindOfType(type: type);

    if (bind is AsyncBind) {
      final value = bind.readAsync();

      // we need to cast the future/value to T.
      if (value is Future) return value.then((it) => it as T);
      return value as T;
    }
    if (null is T) return null as T;
    assert(
      false,
      '''
ReadError: '$type not found'.

Did you provide the missing type?
context.provide<$type>(...); // <- provide it
''',
    );

    throw MissingProvideException('$type not found.');
  }

  final _inheritedScopes = <BuildContext, BuildContext>{};

  /// Establishes a scope relationship from a child context to a parent context.
  ///
  /// This allows [getBindOfType] to traverse the scope hierarchy when looking
  /// for providers in ancestor scopes.
  @protected
  void inheritProviders(BuildContext child, BuildContext parent) {
    assert(child != parent, 'Cannot inherit scope from itself.');
    child.dependOnInheritedElement(_element!);
    _inheritedScopes[child] = parent;
  }

  @protected
  Bind? getBindOfType<T>({String? type, BuildContext? context}) {
    type ??= T.type;

    final binds = _bindCache[type] ?? {};

    if (binds.length > 1 && context != null) {
      if (_scopedBindCache[(type, context)] case var bind?) return bind;

      bool visit(BuildContext ctx) {
        final binds = _binds[ctx]?.values.where((e) => e.type == type);

        if (binds?.isNotEmpty ?? false) {
          assert(
            binds!.length < 2,
            'Duplicate provide<$type> found in the same scope $ctx.',
          );
          _scopedBindCache[(type!, context)] = binds!.first
            .._scopedDependents.add(context);
          return false;
        }

        if (_inheritedScopes[ctx] case var parent?) {
          if (visit(parent)) parent.visitAncestorElements(visit);
          return false;
        }

        return true;
      }

      if (visit(context)) context.visitAncestorElements(visit);
      if (_scopedBindCache[(type, context)] case var bind?) return bind;
    }
    final bind = binds.lastOrNull;

    assert(
      binds.where((it) => !it.deactivated).length < 2,
      'Duplicate provide<$type> found globally.',
    );
    return bind;
  }

  @override
  String toString() => _binds.toString();
}

extension ContextOf on ProvideItScope {
  /// Automatically calls [read] or [watch] based on the [listen] parameter.
  ///
  /// When `listen` is null (default), it automatically decides based on whether
  /// the widget is currently in build/layout/paint pipeline, but you can enforce
  /// specific behavior by explicitly setting `listen` to true or false.
  ///
  T of<T>(BuildContext context, {bool? listen}) {
    listen ??= _element?.isBuilding ?? false;

    if (listen) {
      return watch<T>(context);
    } else {
      return read<T>(context);
    }
  }
}

extension<K, V> on Map<K, V> {
  /// Creates a new [Map] that asserts the given function when mutating.
  ///
  /// This is useful for debugging and testing purposes.
  Map<K, V> _assert(ProvideItScope scope) {
    if (!kDebugMode) return this;

    return AssertMap(this, () {
      final to = scope == readIt ? 'to this scope.' : 'above your app.';
      assert(scope.mounted, 'Scope not attached. You must set a ProvideIt $to');
    });
  }
}

class AssertMap<K, V> extends MapBase<K, V> {
  AssertMap(this._map, this._assert);
  final Map<K, V> _map;
  final VoidCallback _assert;

  @override
  void operator []=(key, value) {
    _assert();
    _map[key] = value;
  }

  @override
  void clear() {
    _assert();
    _map.clear();
  }

  @override
  Iterable<K> get keys {
    _assert();
    return _map.keys;
  }

  @override
  V? remove(Object? key) {
    _assert();
    return _map.remove(key);
  }

  @override
  V? operator [](Object? key) {
    _assert();
    return _map[key];
  }
}

class MissingProvideException implements Exception {
  MissingProvideException(this.message);
  final String message;

  @override
  String toString() => 'MissingProvideException: $message';
}
