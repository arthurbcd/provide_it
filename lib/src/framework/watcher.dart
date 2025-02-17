part of '../framework.dart';

/// An abstract class that represents a watcher for a value of type [T].
///
/// The [Watcher] class provides a mechanism to watch a value and notify
/// dependents when the value changes.
///
/// See also:
/// - [DefaultWatchers].
/// - [ListenableWatcher].
abstract class Watcher<T> {
  RefState? _state;

  /// The value to watch.
  T get value => _state?._lastReadValue as T;

  @protected
  void notify() {
    _state?.notifyDependents();
  }

  /// Whether this watcher can watch [value].
  @protected
  bool canInit(value) => value is T;

  /// Starts watching [value].
  ///
  /// Called when the value is first watched.
  @protected
  void init();

  /// Stops watching [value].
  ///
  /// Called when [value] is no longer being watched.
  @protected
  void cancel();

  /// Disposes of this watcher.
  ///
  /// Called when the [Ref] that created this [value] is disposed.
  @protected
  void dispose();
}
