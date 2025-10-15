part of '../framework.dart';

sealed class ReadIt {
  /// The root [ReadIt] instance.
  ///
  /// Attached to the root [ProvideIt.scope] when null.
  static final ReadIt instance = ProvideItScope();

  /// Creates a fresh instance of [ReadIt].
  ///
  /// Useful for [ProvideIt.scope]. Isolating it from the root [ReadIt] scope.
  factory ReadIt.asNewInstance() => ProvideItScope();

  /// Whether the attached [ProvideIt] is mounted.
  bool get mounted;

  /// Reads the value of a [Ref].
  T read<T>();

  /// Async reads the value of a [AsyncRef].
  FutureOr<T> readAsync<T>();

  /// The future when all [AsyncBind.isReady] are completed.
  FutureOr<void> allReady();

  /// The future when [T] is ready.
  FutureOr<void> isReady<T>();
}

extension CallableReadIt on ReadIt {
  /// Syntactic sugar for [ReadIt.read].
  T call<T>() => read<T>();
}
