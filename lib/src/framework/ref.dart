part of 'framework.dart';

abstract class Ref<T> {
  const Ref({this.key});

  /// The [key] of the [Ref].
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
  void bind(BuildContext context);

  @protected
  RefState<T, Ref<T>> createState();
}
