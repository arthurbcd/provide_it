part of '../framework.dart';

/// A class that tells how to watch an observable [T].
///
/// The [Watcher] class provides a mechanism to watch an observable
/// and notify observers when the it changes.
///
/// See also:
/// - [ListenableWatcher].
/// - [ChangeNotifierWatcher].
abstract class Watcher<T> {
  /// Whether this watcher can watch [observable].
  @protected
  bool canWatch(observable) {
    return observable is T;
  }

  /// Starts watching [observable].
  ///
  /// Called when first read and ready to notify.
  /// - [observable]: The observable to start watching.
  /// - [notify]: The unique callback to register notifications.
  @protected
  void init(T observable, VoidCallback notify);

  /// Stops watching [observable].
  ///
  /// Called when [observable] should stop notifying.
  /// - [observable]: The observable to stop watching.
  /// - [notify]: The unique callback to unregister notifications.
  @protected
  void cancel(T observable, VoidCallback notify);

  /// Disposes this watcher.
  ///
  /// Called when the [Ref] that created this [observable] is disposed.
  @protected
  void dispose(T observable) => false;

  @override
  operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
