part of '../framework.dart';

abstract mixin class ReadIt {
  /// The default root [ProvideIt.scope], also accessible via [readIt].
  /// Automatically attaches to the root [ProvideIt] where [ProvideIt.scope] is null.
  static final ReadIt instance = _ReadItRoot();
  static final ReadIt I = instance;

  /// Creates a new [ReadIt] scope, isolated from [ReadIt.instance] dependencies.
  /// Must attach to a [ProvideIt.scope].
  ///
  /// Useful for creating independent scopes, such as in packages or nested modules.
  /// Example:
  /// ```dart
  /// final myScope = ReadIt.scoped();
  ///
  /// ProvideIt(
  ///   scope: myScope, // creates a new independent scope
  ///   provide: (context) {
  ///     // This scope won't have access to dependencies from ReadIt.instance
  ///     context.provide(() => MyService());
  ///   },
  ///   child: MyApp(),
  /// );
  /// ```
  factory ReadIt.scoped() = _ReadItScope;

  @Deprecated('Use ReadIt.scoped() instead.')
  factory ReadIt.asNewInstance() = ReadIt.scoped;

  /// The future when all [InheritedState.read] can be read synchronously.
  FutureOr<void> allReady();

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>();

  /// Async reads the value of a [InheritedProvider].
  FutureOr<T> readAsync<T>();

  /// Reads the value of [InheritedProvider].
  T read<T>();

  /// Syntactic sugar for [ReadIt.read].
  T call<T>() => read<T>();

  /// Whether is attached to a [ProvideIt] scope.
  bool get attached => false;
}

class _ReadIt with ReadIt {
  ReadIt? _scope;

  @override
  FutureOr<void> allReady() => scope.allReady();

  @override
  FutureOr<void> isReady<T>() => scope.isReady<T>();

  @override
  FutureOr<T> readAsync<T>() => scope.readAsync<T>();

  @override
  T read<T>() => scope.read<T>();

  @override
  bool get attached => _scope != null;
}

class _ReadItRoot extends _ReadIt {}

class _ReadItScope extends _ReadIt {}

extension on _ReadIt {
  ReadIt get scope {
    assert(
      attached,
      this == ReadIt.instance
          ? 'ReadIt not attached. You must set a ProvideIt above your app.'
          : 'ReadIt not attached. You must set it to a ProvideIt.scope.',
    );
    return _scope!;
  }
}
