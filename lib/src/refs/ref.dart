import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

import '../framework.dart';
import 'async.dart';

abstract class Ref<T> {
  const Ref({this.key});

  /// The unique identifier for the [Ref] instance.
  /// Similar to [Widget.key].
  final Object? key;

  /// The default equality for comparing [Ref.key] & [RefState.select] values.
  ///
  /// Obs: `provider` library uses `DeepCollectionEquality.equals` as default.
  static var defaultEquality = (a, b) => switch ((a, b)) {
        (List a, List b) => listEquals(a, b),
        (Set a, Set b) => setEquals(a, b),
        (Map a, Map b) => mapEquals(a, b),
        (var a, var b) => a == b,
      };

  /// A [Widget.canUpdate] implementation for [Ref] with [equals].
  static bool canUpdate(Ref oldRef, Ref newRef) {
    return oldRef.runtimeType == newRef.runtimeType &&
        equals(oldRef.key, newRef.key);
  }

  /// The collection equality for [Ref] keys.
  static bool equals(Object? a, Object? b) => defaultEquality(a, b);

  /// Binds this [Ref] to the [context].
  ///
  /// Will internally call [RefState.bind].
  /// When overridden, both must have the same signature.
  void bind(BuildContext context) => context.bind(this);

  @protected
  RefState<T, Ref<T>> createState();
}

extension RefReaders<T> on Ref<T> {
  /// Reads the value of this [Ref]. Auto-binds if not already.
  T read(BuildContext context) {
    return context.read(key: this);
  }

  /// Watches the value of this [Ref]. Auto-binds if not already.
  T watch(BuildContext context) {
    return context.watch(key: this);
  }

  /// Selects a value from this [Ref] using [selector].
  R select<R>(BuildContext context, R selector(T value)) {
    return context.select(selector, key: this);
  }

  /// Listens to the value of this [Ref] using [listener].
  void listen(BuildContext context, void listener(T value)) {
    context.listen(listener, key: this);
  }

  /// Listens to the value of this [Ref] using [selector] and [listener].
  void listenSelect<R>(
    BuildContext context,
    R selector(T value),
    void listener(R? previous, R next),
  ) {
    context.listenSelect(selector, listener, key: this);
  }
}

extension AsyncRefReaders<T> on AsyncRef<T> {
  /// Reloads the value of this [Ref].
  Future<void> reload(BuildContext context) {
    return context.reload(key: this);
  }

  /// Async reads the value of this [Ref].
  FutureOr<T> readAsync(BuildContext context) {
    return context.readAsync(key: this);
  }

  /// The future when this [Ref] is ready to be read.
  FutureOr<void> isReady(BuildContext context) {
    return context.readAsync(key: this);
  }

  /// Whether this [Ref] is ready to be read.
  bool isReadySync(BuildContext context) => isReady(context) == null;
}
