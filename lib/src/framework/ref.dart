part of '../framework.dart';

abstract class Ref<T> {
  /// The [key] of the [Ref].
  Object? get key;

  /// Creates a new [ProvideRef] with the given [key], [create] and [dispose].
  factory Ref(Create<T> create, {Dispose<T>? dispose, Object? key}) {
    return ProvideRef<T>(create, dispose: dispose, key: key);
  }

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
  void bind(BuildContext context);

  @protected
  RefState<T, Ref<T>> createState();
}

extension RefExtension<T> on Ref<T> {
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
  void listenSelect<R>(BuildContext context, R selector(T value),
      void listener(R? previous, R next)) {
    context.listenSelect(selector, listener, key: this);
  }
}
