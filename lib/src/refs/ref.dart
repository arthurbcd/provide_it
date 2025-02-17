import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../framework.dart';

abstract class Ref<T> {
  const Ref({this.key});

  /// The unique identifier for the [Ref] instance.
  /// Equivalent to [Widget.key].
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

extension RefBinder on BuildContext {
  /// Shortcut to bind a [Ref] to this [BuildContext].
  ///
  /// Use it to override [Ref.bind] to declare a custom [R] return type:
  /// ```dart
  /// @override
  /// T bind(BuildContext context) => context.bind(this);
  /// ```
  /// See: [CreateRef] or [ValueRef].
  R bind<R, T>(Ref<T> ref) {
    return _instance.bind(this, ref);
  }
}

extension RefReaders<T> on Ref<T> {
  /// Reads the value of this [Ref]. Auto-binds if not already.
  T read(BuildContext context) {
    return _instance.read(context, key: this);
  }

  /// Watches the value of this [Ref]. Auto-binds if not already.
  T watch(BuildContext context) {
    return _instance.watch(context, key: this);
  }

  /// Selects a value from this [Ref] using [selector].
  R select<R>(BuildContext context, R selector(T value)) {
    return _instance.select(context, selector, key: this);
  }

  /// Listens to the value of this [Ref] using [listener].
  void listen(BuildContext context, void listener(T value)) {
    _instance.listen(context, listener, key: this);
  }

  /// Listens to the value of this [Ref] using [selector] and [listener].
  void listenSelect<R>(BuildContext context, R selector(T value),
      void listener(R? previous, R next)) {
    _instance.listenSelect(context, selector, listener, key: this);
  }
}

ProvideItElement get _instance => ProvideItElement.instance;
