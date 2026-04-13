part of '../framework.dart';

typedef ErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace stackTrace);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.setup,
    this.provide,
    this.watchers = const [ListenableWatcher()],
    this.loadingBuilder = _loadingBuilder,
    this.errorBuilder = _errorBuilder,
    required super.child,
  }) : assert(provide is! Future<void> Function(BuildContext), '''
ProvideIt.provide must be sync.
You can use `async` directly in `setup` or `context.provideAsync`:

ProvideIt(
  provide: (context) { // <- DO NOT mark it as async.

    // Use async operations here:
    context.provideAsync(() async {
      final value = await myAsyncValue();
      return value;
    });

    // Or simply:
    context.provideAsync(myAsyncValue);
  },
  child: MyApp(),
);
''');

  static Widget _loadingBuilder(BuildContext context) =>
      const SizedBox.shrink();

  static Widget _errorBuilder(BuildContext context, Object e, StackTrace s) =>
      ErrorWidget(e);

  /// The default equality to use. Defaults to one-depth collections equality.
  /// Override it to `DeepCollectionEquality.equals` to mimic lib `provider` behavior.
  static var equals = (Object? a, Object? b) => switch ((a, b)) {
    (List a, List b) => listEquals(a, b),
    (Set a, Set b) => setEquals(a, b),
    (Map a, Map b) => mapEquals(a, b),
    _ => a == b,
  };

  /// Perform any async setup before [provide] is called. Called once.
  /// If it returns a [Future], [loadingBuilder] will be shown until it completes.
  final FutureOr<void> Function()? setup;

  /// Initializes [ProvideIt] and sets up root providers.
  ///
  /// The [provide] callback follows [ReadIt.allReady], showing:
  /// - [loadingBuilder]: when any async provider is loading.
  /// - [errorBuilder]: when any async provider fails to load.
  /// - [child]: when all async providers are ready.
  ///
  /// If [provide] is `null` or no async provider is found, [child] is immediately displayed.
  final void Function(BuildContext context)? provide;

  /// The builder to use if [provide] is marked with `async`.
  final WidgetBuilder loadingBuilder;

  /// The builder to use if an error occurs during [provide].
  final ErrorBuilder errorBuilder;

  /// [Watcher]s are used to automatically watch for changes in providers such as:
  /// - `context.provide`: [_Inherited]
  /// - `context.provideValue`: [_Inherited.value]
  ///
  /// You can create your own [Watcher] by extending the class and setting in [watchers].
  /// By default, [ListenableWatcher] is used to watch for [Listenable] changes.
  ///
  /// The first matching [Watcher.canWatch] will be used to watch the provider value.
  ///
  /// Watchers are not used by `context.use` / `context.useValue`.
  ///
  final List<Watcher> watchers;

  /// Returns the first matching [Watcher] for the given value.
  Watcher? resolveWatcher(Object value) {
    for (var i = 0; i < watchers.length; i++) {
      if (watchers[i] case final watcher when watcher.canWatch(value)) {
        return watcher;
      }
    }
    return null;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  @override
  InheritedElement createElement() => ScopeIt(this);
}

class ScopeIt extends InheritedScope with BindIt, InheritIt, DependIt, ReadIt {
  ScopeIt(ProvideIt super.widget);

  static ScopeIt of(BuildContext context) {
    final scope = context.getElementForInheritedWidgetOfExactType<ProvideIt>();
    assert(scope != null, 'You must set a `ProvideIt` above your app.');
    return scope as ScopeIt;
  }

  @override
  ProvideIt get widget => super.widget as ProvideIt;

  @override
  Widget build() {
    switch (useFuture(widget.setup)) {
      case AsyncSnapshot(connectionState: ConnectionState.waiting):
        return widget.loadingBuilder(this);
      case AsyncSnapshot(:final error?, :final stackTrace?):
        return widget.errorBuilder(this, error, stackTrace);
    }

    try {
      widget.provide?.call(this);
    } catch (error, stackTrace) {
      return widget.errorBuilder(this, error, stackTrace);
    }

    switch (useFuture(allReady)) {
      case AsyncSnapshot(connectionState: ConnectionState.waiting):
        return widget.loadingBuilder(this);
      case AsyncSnapshot(:final error?, :final stackTrace?):
        return widget.errorBuilder(this, error, stackTrace);
    }

    return widget.child;
  }
}

class Node extends NodeBase with Bindings, Dependencies {
  Node(super.dependent);
}

extension type ReadKey._(GlobalKey _) implements Key {
  /// Creates a [ReadKey] for contextless reading.
  /// Must be attached to [ProvideIt.key] or any descendant [Widget.key].
  factory ReadKey({String? debugLabel}) =>
      ReadKey._(GlobalKey(debugLabel: debugLabel));

  /// [ContextReaders.read].
  T call<T>() => read<T>();

  /// [ContextReaders.read].
  T read<T>() {
    if (_scope?.read<T>() case T value) return value;
    throw _notAttached;
  }

  /// [ContextReaders.readAsync].
  FutureOr<T> readAsync<T>() {
    if (_scope?.readAsync<T>() case T value) return value;
    throw _notAttached;
  }

  /// [ContextReaders.isReady].
  FutureOr<void> isReady<T>() {
    if (null is! T && _scope == null) throw _notAttached;
    return _scope?.isReady<T>();
  }

  /// [ContextReaders.allReady].
  FutureOr<void> allReady() {
    if (_scope == null) throw _notAttached;
    return _scope?.allReady();
  }

  Error get _notAttached =>
      StateError('ReadKey not attached. You must set it to a Widget.key.');

  ScopeIt? get _scope => switch (_.currentContext) {
    ScopeIt scope => scope,
    final context? => ScopeIt.of(context),
    _ => null,
  };
}
