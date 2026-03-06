part of '../framework.dart';

/// A class that tells how to watch an observable [T].
///
/// The [Watcher] class provides a mechanism to watch an observable
/// and notify observers when the it changes.
///
/// See also:
/// - [ListenableWatcher].
abstract class Watcher<T> {
  const Watcher();

  /// Whether this watcher can watch [value].
  @protected
  @mustCallSuper
  bool canWatch(value) {
    return value is T;
  }

  /// Starts watching [value].
  ///
  /// Called when first read and ready to watch.
  /// - [value]: The observable to start watching.
  /// - [listener]: The unique callback to notify on changes.
  @protected
  void init(T value, VoidCallback listener);

  /// Stops watching [value].
  ///
  /// Called when [value] should stop watching.
  /// - [value]: The observable to stop watching.
  /// - [listener]: The same unique callback passed to [init].
  @protected
  void cancel(T value, VoidCallback listener);

  /// Disposes this watcher.
  ///
  /// Called when the [InheritedState] that created this [value] is disposed.
  @protected
  void dispose(T value);
}
