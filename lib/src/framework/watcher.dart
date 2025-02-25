part of '../framework.dart';

/// An abstract class that represents a watcher for a value of type [T].
///
/// The [Watcher] class provides a mechanism to watch a value and notify
/// dependents when the value changes.
///
/// See also:
/// - [DefaultWatchers].
/// - [ListenableWatcher].
/// - [ChangeNotifierWatcher].
abstract class Watcher<T> {
  RefState? _state;

  /// The value to watch.
  T get value => _state?.value;

  @protected
  void notify() {
    _state?.notifyDependents();
  }

  /// Whether this watcher can watch [value].
  @protected
  bool canWatch(value) {
    return value is T;
  }

  /// Starts watching [value].
  ///
  /// Called lazily when [value] is first read.
  @protected
  void init();

  /// Stops watching [value].
  ///
  /// Called when [value] is no longer being watched.
  @protected
  void cancel();

  /// Disposes this watcher.
  ///
  /// Called when the [Ref] that created this [value] is disposed.
  @protected
  void dispose();

  @override
  operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
