part of '../framework.dart';

/// A class that tells how to watch a provider [T] value.
///
/// The [Watcher] class provides a mechanism to watch an observable
/// and notify observers when the it changes.
///
/// See also:
/// - [ListenableWatcher].
abstract class Watcher<T extends Object> {
  const Watcher();

  /// Whether this watcher can watch [value].
  @mustCallSuper
  bool canWatch(Object value) => value is T;

  /// Starts watching [value].
  ///
  /// Called when when first depending and ready to watch.
  /// - [value]: The observable to start watching.
  /// - [notify]: The unique callback to notify on changes.
  @protected
  void listen(T value, VoidCallback notify);

  /// Stops watching [value].
  ///
  /// Called when [value] should stop watching.
  /// - [value]: The observable to stop watching.
  /// - [notify]: The same unique callback passed to [listen].
  @protected
  void cancel(T value, VoidCallback notify);

  /// Disposes this watcher.
  ///
  /// Called when the [InheritedState] that created this [value] is disposed.
  @protected
  void dispose(T value);
}
