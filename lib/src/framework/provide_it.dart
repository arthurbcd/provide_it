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

  /// Restart the nearest [ProvideIt] subtree and all its bind dependencies.
  static void restart(BuildContext context) {
    ScopeIt.of(context).restart();
  }

  static Widget _loadingBuilder(BuildContext context) {
    return const SizedBox.shrink();
  }

  static Widget _errorBuilder(BuildContext context, Object e, StackTrace s) {
    return ErrorWidget(e);
  }

  /// Creates an [Injector] of type [T] that auto-injects registered dependencies.
  /// - Uses [locator] & [parameters] for additional dependency injection.
  ///
  /// Used by [ContextProvide] to inject dependencies.
  static Injector<T> injectorOf<T>(BuildContext context, Function create) {
    final ScopeIt scope = ScopeIt.of(context);
    final ProvideIt it = scope.widget;

    return Injector<T>(
      create,
      parameters: it.parameters,
      locator: (param) {
        return it.locator?.call(param) ?? scope.readAsync(type: param.type);
      },
    );
  }

  static Watcher<T>? watcherOf<T>(BuildContext context, T value) {
    final watchers = ScopeIt.of(context).widget.watchers;

    for (var i = 0; i < watchers.length; i++) {
      final watcher = watchers[i];
      if (watcher.canWatch(value)) {
        return watcher as Watcher<T>;
      }
    }
    return null;
  }

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

  /// The [Injector.parameters] to use in all injectors below this [ProvideIt].
  final Map<String, dynamic>? parameters;

  /// The [ReadIt] scope to use. When `null`, defaults to:
  /// - [ReadIt.instance] when root.
  /// - [ReadIt.asNewInstance] when not root.
  final ReadIt? scope;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  @override
  InheritedElement createElement() => ScopeIt(this);
}
