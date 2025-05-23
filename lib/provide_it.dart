library;

import 'package:flutter/foundation.dart';
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

typedef _AsyncProvide = Future<void> Function(BuildContext context);

class ProvideIt extends InheritedWidget {
  const ProvideIt({
    super.key,
    this.scope,
    this.provide,
    this.locator,
    this.parameters,
    this.allowedDuplicates = const [],
    this.additionalWatchers = const [],
    this.loadingBuilder = _loadingBuilder,
    this.errorBuilder = _errorBuilder,
    required super.child,
  }) : assert(provide is! _AsyncProvide, _assert);

  static const _assert = '''
ProvideIt.provide must be void. 
If you want need async, use it directly in a `provide`:

ProvideIt(
  provide: (context) {

    // Use async operations here:
    context.provide(() async {
      final value = await MyAsyncValue.init();
      return value;
    });

    // Or simply:
    context.provide(MyAsyncValue.init);
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

  static Widget _loadingBuilder(BuildContext context) {
    return Center(child: CircularProgressIndicator.adaptive());
  }

  static Widget _errorBuilder(BuildContext context, Object e, StackTrace s) {
    return Center(child: Text(kDebugMode ? '$e\n$s' : '$e'));
  }

  /// Initializes [ProvideIt] and sets up app-wide bindings.
  ///
  /// The [provide] follows [ReadIt.allReady], calling:
  /// - [loadingBuilder]: when any async bind is loading.
  /// - [errorBuilder]: when any async bind fails to load.
  /// - [child]: when all async binds are ready.
  ///
  /// If [provide] is `null`, the [child] will be displayed immediately.
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

  /// List of types allowed to have duplicate values on read.
  ///
  /// Types not in this list will be treated as strict and cannot have duplicate values,
  /// unless a key exists to differentiate them.
  ///
  /// - Set to `[]` to strictly enforce no duplicates.
  /// - Set to `null` to allow duplicates for all types.
  ///
  /// Using binds directly does not enforce this rule, as you are not
  /// reading it from the context.
  ///
  /// ```dart
  /// // when using locally, duplicates are always allowed.
  /// final (name, setName) = context.value('');
  /// final (title, setTitle) = context.value('');
  /// final (email, setEmail) = context.value('', key: 'email');
  ///
  /// // unless `allowedDuplicates` contains `String`, then:
  /// final title = context.read<String>(); // not allowed
  /// final email = context.read<String>(key: 'email'); // allowed
  /// ```
  final List<Type>? allowedDuplicates;

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
  /// - [ReadIt.asNewInstance] when not root.l l
  final ReadIt? scope;

  @override
  bool updateShouldNotify(covariant ProvideIt oldWidget) => false;

  @override
  InheritedElement createElement() => ProvideItElement(this);
}
