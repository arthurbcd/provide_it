part of '../framework.dart';

typedef ErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace stackTrace);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.scope,
    this.provide,
    this.watchers = const [ListenableWatcher()],
    this.loadingBuilder = _loadingBuilder,
    this.errorBuilder = _errorBuilder,
    this.locator,
    this.parameters,
    required super.child,
  }) : assert(
         scope is! _ReadItRoot,
         'ReadIt.instance can\'t be used as a scope. Remove it or use ReadIt.scoped() instead.',
       ),
       assert(
         scope is _ReadItScope?,
         'Invalid scope. Only ReadIt.scoped() can be used as a scope.',
       ),
       assert(provide is! Future<void> Function(BuildContext), '''
ProvideIt.provide must be sync.
You can use `async` directly in a `context.provideAsync`:

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

  static ProvideIt? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProvideIt>();
  }

  static Widget _loadingBuilder(BuildContext context) {
    return const SizedBox.shrink();
  }

  static Widget _errorBuilder(BuildContext context, Object e, StackTrace s) {
    return ErrorWidget(e);
  }

  /// The default equality to use. Defaults to one-depth collections equality.
  /// Override it to `DeepCollectionEquality.equals` to mimic lib `provider` behavior.
  static Equals equals = (Object? a, Object? b) => switch ((a, b)) {
    (List a, List b) => listEquals(a, b),
    (Set a, Set b) => setEquals(a, b),
    (Map a, Map b) => mapEquals(a, b),
    _ => a == b,
  };

  /// Initializes [ProvideIt] and sets up root [ContextProviders].
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

  /// Injects a [Param] during creation.
  ///
  /// Example with router path parameters:
  ///
  /// ```dart
  /// ProvideIt(
  ///   locator: (param) => myRouter.pathParameters[param.name],
  ///   child: MyApp(),
  /// );
  /// ```
  ///
  /// Auto-injects `pathParameters` to `MyClass.new`:
  ///
  /// ```dart
  /// class MyClass {
  ///   MyClass({required this.myId});
  ///   final String myId; // auto-injected if pathParameters['myId'] exists.
  /// }
  /// ```
  final ParamLocator? locator;

  /// Shared [Injector.parameters] for all [ContextProvide] below this [ProvideIt].
  final Map<Symbol, dynamic>? parameters;

  /// The [ReadIt] scope to use. When `null`, defaults to:
  /// - [ReadIt.instance] when root.
  /// - [ReadIt.asNewInstance] when not root.
  final ReadIt? scope;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

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
  InheritedElement createElement() => ScopeIt(this);
}

@internal
typedef Equals = bool Function(Object? a, Object? b);
