library;

import 'package:flutter/material.dart';

import 'provide_it.dart';
import 'src/framework.dart';
import 'src/injector/injector.dart';

export 'src/core.dart';
export 'src/framework.dart' hide ProvideItElement, ProvideItScope;
export 'src/refs/async.dart';
export 'src/refs/create.dart';
export 'src/refs/future.dart';
export 'src/refs/init.dart';
export 'src/refs/provide.dart';
export 'src/refs/provider/consumer.dart';
export 'src/refs/provider/future_provider.dart';
export 'src/refs/provider/multi_provider.dart';
export 'src/refs/provider/provider.dart';
export 'src/refs/provider/value_listenable_provider.dart';
export 'src/refs/ref.dart';
export 'src/refs/stream.dart';
export 'src/refs/value.dart';
export 'src/utils/async_snapshot_extension.dart';
export 'src/watchers/change_notifier.dart';
export 'src/watchers/listenable.dart';

// TODO(arthurbcd): add tests:
// ## 0.18.4
// ## 0.18.5
// ## 0.18.6

typedef ErrorBuilder = Widget Function(
    BuildContext context, Object error, StackTrace stackTrace);

typedef _Async = Future<void> Function(BuildContext context);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.scope,
    this.override,
    this.provide,
    this.locator,
    this.parameters,
    this.additionalWatchers = const [],
    this.loadingBuilder = _loadingBuilder,
    this.errorBuilder = _errorBuilder,
    required super.child,
  }) : assert(provide is! _Async && override is! _Async, _notAsyncMessage);

  static const _notAsyncMessage = '''
ProvideIt.provide and ProvideIt.override must be void. 
If you need async, use it directly in a `provide`:

ProvideIt(
  provide: (context) { // <- DO NOT mark it as async.

    // Use async operations here:
    context.provide(() async {
      final value = await MyAsyncValue.async();
      return value;
    });

    // Or simply:
    context.provide(MyAsyncValue.async);
  },
  child: MyApp(),
);
''';

  /// Default watchers to use when providing an observable value.
  ///
  /// To disable, set: `ProvideIt.defaultWatchers = []`.
  static Set<Watcher> defaultWatchers = {
    ListenableWatcher(),
    ChangeNotifierWatcher(),
  };

  /// Restart the nearest [ProvideIt] subtree and all its bind dependencies.
  static void restart(BuildContext context) {
    ProvideItElement.of(context).restart();
  }

  static Widget _loadingBuilder(BuildContext context) {
    return Center(child: CircularProgressIndicator.adaptive());
  }

  static Widget _errorBuilder(BuildContext context, Object e, StackTrace s) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: '$s',
                child: Text('$e'),
              ),
              TextButton(
                onPressed: () => ProvideIt.restart(context),
                child: Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Overrides existing providers or values within this [ProvideIt] scope.
  ///
  /// The [override] callback is executed before [provide], allowing you to
  /// replace dependencies for testing or specific subtrees.
  final void Function(OverrideContext context)? override;

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

  /// Extra watchers to use:
  /// - [ProvideIt.defaultWatchers] + [additionalWatchers].
  ///
  /// A [Bind] can have exactly one [Watcher]. Starting from last,
  /// returns the first watcher that [Watcher.canWatch]. So [additionalWatchers]
  /// can override [defaultWatchers].
  ///
  /// To disable [defaultWatchers], set: `ProvideIt.defaultWatchers = []`.
  final List<Watcher> additionalWatchers;

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

  // ignore: annotate_overrides
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  // ignore: annotate_overrides
  InheritedElement createElement() => ProvideItElement(this);
}

extension type OverrideContext(ProvideItElement _) implements BuildContext {
  void override<T extends Object>(T value) {
    assert(T != dynamic || T != Object, 'Cannot override dynamic or Object');
    assert(
      T != value.runtimeType,
      'Missing override<Type> for $T.\nEx: context.override<Counter>(FakeCounter())',
    );
    _.overrides[T.toString()] = OverrideRef<T>(value);
  }
}
