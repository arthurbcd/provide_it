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

  /// Whether this watcher can watch [observable].
  @protected
  @mustCallSuper
  bool canWatch(observable) {
    return observable is T;
  }

  /// Starts watching [observable].
  ///
  /// Called when first read and ready to watch.
  /// - [observable]: The observable to start watching.
  /// - [listener]: The unique callback to notify on changes.
  @protected
  void init(T observable, VoidCallback listener);

  /// Stops watching [observable].
  ///
  /// Called when [observable] should stop watching.
  /// - [observable]: The observable to stop watching.
  /// - [listener]: The same unique callback passed to [init].
  @protected
  void cancel(T observable, VoidCallback listener);

  /// Disposes this watcher.
  ///
  /// Called when the [InheritedState] that created this [observable] is disposed.
  @protected
  void dispose(T observable);

  @override
  operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
