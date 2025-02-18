import 'package:flutter/material.dart';

/// Extension on [AsyncSnapshot] to handle its various states
extension AsyncSnapshotExtension<T> on AsyncSnapshot<T> {
  /// Allows you to define custom behavior for different states of an [AsyncSnapshot]
  /// by providing callbacks for `data`, `error`, `loading`, and `none`.
  ///
  /// - [data] Callbacks when snapshot has [T] data.
  /// - [error] Callbacks when snapshot [hasError].
  /// - [loading] Callbacks when snapshot [isLoading] and [hasNone].
  /// - [none] Optionally callbacks when snapshot not [isLoading] and [hasNone].
  ///
  /// Example:
  /// ```dart
  /// snapshot.when(
  ///   data: (data) => Text('Data: $data'),
  ///   error: (error, stack) => Text('Error: $error'),
  ///   loading: () => CircularProgressIndicator(),
  ///   none: () => Text('No error or data'),
  /// );
  /// ```
  ///
  /// Use [none] for uncommon scenarios where [data], [error], and [loading] are
  /// not applicable. For instance, to display a widget when there's no data, no
  /// error, and no ongoing loading, or when a [Stream] is cancelled without
  /// emitting any data or error (e.g [Stream.empty]).
  ///
  /// If [none] is not provided:
  /// - [loading] will be called when init [hasNone].
  /// - [StateError] will be thrown when done [hasNone].
  ///
  /// If [skipLoading] is `true`, [loading] won't be called when [AsyncSnapshot]
  /// [hasData] or [hasError]. Instead, [data] or [error] will be called.
  ///
  /// It's recommended to use [isReloading] in conjunction with [skipLoading].
  /// So all states are handled by ui.
  ///
  /// Example:
  /// ```dart
  /// Stack(
  ///   alignment: Alignment.center,
  ///   children: [
  ///     snapshot.when(
  ///       skipLoading: true,
  ///       data: (data) => Text('Data: $data'),
  ///       error: (error, stack) => Text('Error: $error'),
  ///       loading: () => CircularProgressIndicator(),
  ///       none: () => Text('No error or data'),
  ///     );
  ///     if(snapshot.isReloading)
  ///     Align(
  ///       alignment: Alignment.topCenter,
  ///       child: LinearProgressIndicator(),
  ///     ),
  ///   ],
  /// )
  /// ```
  R when<R>({
    bool skipLoading = false,
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace) error,
    required R Function() loading,
    R Function()? none,
  }) {
    if (isLoading && !skipLoading) return loading();
    if (hasData) return data(this.data as T);
    if (hasError) return error(this.error!, stackTrace!);

    return switch (connectionState) {
      ConnectionState.none => none != null ? none() : loading(),
      ConnectionState.waiting => loading(),
      ConnectionState.active => loading(),
      ConnectionState.done when this.data is T => data(this.data as T),
      _ => none != null ? none() : data(requireData),
    };
  }

  /// Allows you to define custom behavior for different states of an [AsyncSnapshot]
  /// by providing callbacks for `data`, `error`, `loading`, and `none`.
  ///
  /// Same as [when] but returns null for unhandled states.
  R? whenOrNull<R>({
    bool skipLoading = false,
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    R Function()? loading,
    R Function()? none,
  }) {
    return when(
      skipLoading: skipLoading,
      data: data ?? (_) => null,
      error: error ?? (_, __) => null,
      loading: loading ?? () => null,
      none: none ?? () => null,
    );
  }

  /// Allows you to define custom behavior for different states of an [AsyncSnapshot]
  /// by providing callbacks for `data`, `error`, `loading`, and `none`.
  ///
  /// Same as [when] but requires a default [orElse] for unhandled states.
  R maybeWhen<R>({
    bool skipLoading = false,
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    R Function()? loading,
    R Function()? none,
    required R Function() orElse,
  }) {
    return when(
      skipLoading: skipLoading,
      data: data ?? (_) => orElse(),
      error: error ?? (_, __) => orElse(),
      loading: loading ?? orElse,
      none: none ?? orElse,
    );
  }

  /// Returns whether this snapshot has neither [data]/[error].
  bool get hasNone => !hasData && !hasError;

  /// Returns whether this snapshot is computing.
  bool get isLoading =>
      connectionState == ConnectionState.waiting ||
      connectionState == ConnectionState.active;

  /// Returns whether this snapshot is computing and has [data]/[error].
  bool get isReloading => (hasData || hasError) && isLoading;

  /// Applies [map] when this snapshot [hasData].
  AsyncSnapshot<R> whenData<R>(
    R Function(T data) map,
  ) {
    if (hasError) {
      return AsyncSnapshot.withError(connectionState, error!, stackTrace!);
    }
    if (hasData) {
      return AsyncSnapshot.withData(connectionState, map(data as T));
    }
    return AsyncSnapshot<R>.nothing().inState(connectionState);
  }

  /// Applies [map] when this snapshot [hasError].
  AsyncSnapshot<T> whenError(
    Object Function(Object error) map,
  ) {
    if (hasError) {
      return AsyncSnapshot.withError(connectionState, map(error!), stackTrace!);
    }
    if (hasData) {
      return AsyncSnapshot.withData(connectionState, data as T);
    }
    return AsyncSnapshot<T>.nothing().inState(connectionState);
  }
}
