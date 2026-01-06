import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../provide_it.dart';
import '../framework.dart';

/// The base class for all [Ref] types.
///
/// Refs are used to provide values to the widget tree.
/// They are similar to [InheritedWidget] but with more features.
/// - They are not limited to the current widget tree.
/// - As long as the [Ref] is bound to a [BuildContext], it can be used anywhere.
/// - They can be used to manage the lifecycle of values with [Bind].
/// - They automatically dispose when the [BuildContext] is unmounted.
/// - You can `read`, `watch`, `listen`, and `select` bind values.
///
/// You must set [ProvideIt] in the root of your app.
///
/// See [Bind] for more details.
abstract class Ref<T> {
  const Ref({this.key});

  /// The unique identifier for the [Ref] instance.
  /// Similar to [Widget.key].
  final Object? key;

  /// Creates a [T] value to bind. Can return a deferred [T], e.g: [Future] or [Stream].
  /// When null, the [Bind] will not manage the value lifecycle or disposal.
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
  static bool canUpdate(Ref oldRef, Ref newRef) {
    return oldRef.runtimeType == newRef.runtimeType &&
        equals(oldRef.key, newRef.key);
  }

  /// The equality used for [Ref.key] & [Bind.select].
  static bool equals(Object? a, Object? b) => defaultEquals(a, b);

  @protected
  Bind<T, Ref<T>> createBind();
}

extension RefReaders<T> on Ref<T> {
  /// Binds this [Ref] to the [BuildContext].
  @protected
  Bind<T, Ref<T>> bind(BuildContext context) {
    return ProvideItScope.of(context).bind(context, this);
  }
}
