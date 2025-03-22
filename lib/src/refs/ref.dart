import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../provide_it.dart';

/// The base class for all [Ref] types.
///
/// Refs are used to provide values to the widget tree.
/// They are similar to [InheritedWidget] but with more features.
/// - They are not limited to the current widget tree.
/// - As long as the [Ref] is bound to a [BuildContext], it can be used anywhere.
/// - They can be used to manage the lifecycle of values with [RefState].
/// - They automatically dispose when the [BuildContext] is unmounted.
/// - You can `read`, `watch`, `listen`, and `select` values.
///
/// You must set [ProvideIt] in the root of your app.
///
/// See [RefState] for more details.
abstract class Ref<T> {
  const Ref({this.key = id});

  /// The unique identifier for the [Ref] instance.
  /// Similar to [Widget.key].
  final Object? key;

  /// Creates a [T] value to provide.
  /// Can return a deferred [T], e.g. a [Future] or [Stream].
  Function? get create;

  /// The default equality to use in [equals]. Defaults to one-depth collections equality.
  /// Override it to `DeepCollectionEquality.equals` to mimic lib `provider` behavior.
  static var defaultEquals = (a, b) => switch ((a, b)) {
        (List a, List b) => listEquals(a, b),
        (Set a, Set b) => setEquals(a, b),
        (Map a, Map b) => mapEquals(a, b),
        _ => a == b,
      };

  /// A [Widget.canUpdate] implementation for [Ref] with [equals].
  static bool canUpdate(Ref oldRef, Ref newRef) =>
      identical(oldRef, newRef) ||
      (oldRef.runtimeType == newRef.runtimeType &&
          equals(oldRef.key, newRef.key));

  /// The equality used for [Ref.key] & [RefState.select].
  static bool equals(Object? a, Object? b) => defaultEquals(a, b);

  /// Signature for using [Ref] own identity as [key].
  /// Only available for a top-level [Ref].
  @protected
  static void id() {}

  @protected
  RefState<T, Ref<T>> createState();
}

extension RefReaders<T> on Ref<T> {
  /// Binds this [Ref] to the [BuildContext].
  @protected
  RefState<T, Ref<T>> bind(BuildContext context) => context.bind(this);

  /// Gets the [RefState] of this [Ref].
  @protected
  RefState<T, Ref<T>> bindOf(BuildContext context) {
    return context.bindOf<T>(key: this) as RefState<T, Ref<T>>;
  }

  /// Reads a previously bound [T] value.
  T read(BuildContext context) {
    return context.read(key: this);
  }

  /// Watches this [T] value. Auto-binds.
  T watch(BuildContext context) {
    return context.watch(key: this);
  }

  /// Selects this [R] value using [selector]. Auto-binds.
  R select<R>(BuildContext context, R selector(T value)) {
    return context.select(selector, key: this);
  }

  /// Listens this [T] value using [listener]. Auto-binds.
  void listen(BuildContext context, void listener(T value)) {
    context.listen(listener, key: this);
  }

  /// Listens this [R] value using [selector] and [listener]. Auto-binds.
  void listenSelect<R>(
    BuildContext context,
    R selector(T value),
    void listener(R? previous, R next),
  ) {
    context.listenSelect(selector, listener, key: this);
  }
}

extension AsyncRefBinder<T> on AsyncRef<T> {
  /// Binds the [AsyncRef] to the [BuildContext].
  AsyncRefState<T, AsyncRef<T>> bind(BuildContext context) {
    return context.bind(this) as AsyncRefState<T, AsyncRef<T>>;
  }

  AsyncRefState<T, AsyncRef<T>> bindOf(BuildContext context) {
    return context.bindOf<T>(key: this) as AsyncRefState<T, AsyncRef<T>>;
  }

  /// Watches the [AsyncSnapshot] of this async value.
  AsyncSnapshot<T> watch(BuildContext context) {
    return bindOf(context).watch(context);
  }
}

extension AsyncRefReaders<T> on AsyncRef<T> {
  /// Reloads the value of this [Ref].
  Future<void> reload(BuildContext context) {
    return context.reload<T>(key: this);
  }

  /// Async reads the value of this [Ref].
  FutureOr<T> readAsync(BuildContext context) {
    return context.readAsync<T>(key: this);
  }

  /// The future when this [Ref] is ready to be read.
  FutureOr<void> isReady(BuildContext context) {
    return context.readAsync<T>(key: this);
  }

  /// Whether this [Ref] is ready to be read.
  bool isReadySync(BuildContext context) => isReady(context) == null;
}
