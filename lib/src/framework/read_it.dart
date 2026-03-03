part of '../framework.dart';

sealed class ReadIt {
  /// The root [ReadIt] instance.
  /// Also accessible via [readIt].
  ///
  /// Attached to the root [ProvideIt.scope] when null.
  static final ReadIt instance = ProvideItContainer();

  /// Creates a fresh instance of [ReadIt].
  ///
  /// Useful for [ProvideIt.scope]. Isolating it from the root [ReadIt] scope.
  factory ReadIt.asNewInstance() => ProvideItContainer();

  /// Whether the attached [ProvideIt] is mounted.
  bool get mounted;

  /// Reads the value of [InheritedProvider].
  T read<T>();

  /// Async reads the value of a [InheritedProvider].
  FutureOr<T> readAsync<T>();

  /// The future when all [InheritedState.read] can be read synchronously.
  FutureOr<void> allReady();

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>();
}

extension CallableReadIt on ReadIt {
  /// Syntactic sugar for [ReadIt.read].
  T call<T>() => read<T>();
}
