part of '../framework.dart';

@internal
abstract class AnyProvider<T, R> with Diagnosticable {
  const AnyProvider({this.key});

  /// Controls how one provider replaces another in the bind tree.
  /// Similar to [Widget.key].
  final Object? key;

  /// A [Widget.canUpdate] implementation for [AnyProvider] with [equals].
  static bool canUpdate(AnyProvider oldProvider, AnyProvider newProvider) {
    return oldProvider.runtimeType == newProvider.runtimeType &&
        equals(oldProvider.key, newProvider.key);
  }

  /// The default equality to use. Defaults to one-depth collections equality.
  /// Override it to `DeepCollectionEquality.equals` to mimic lib `provider` behavior.
  static Equals equals = (Object? a, Object? b) => switch ((a, b)) {
    (List a, List b) => listEquals(a, b),
    (Set a, Set b) => setEquals(a, b),
    (Map a, Map b) => mapEquals(a, b),
    _ => a == b,
  };

  @protected
  ProviderState<T, R> createState();
}

extension ContextBind on BuildContext {
  R bind<T, R>(AnyProvider<T, R> provider) {
    return ProvideItContainer.of(this).bind(this, provider);
  }
}

@internal
typedef Equals = bool Function(Object? a, Object? b);

typedef _ProviderBind<T, R> = ({
  AnyProvider<T, R> provider,
  Element element,
  int index,
});

@internal
sealed class ProviderState<T, R> with Diagnosticable {
  _ProviderBind<T, R>? _bind;

  @visibleForTesting
  String get debugLabel;

  @visibleForTesting
  int get index => _bind!.index;

  /// The [context] this [AnyProvider] is bound to.
  BuildContext get context => _bind!.element;

  /// The [AnyProvider] that this state is associated with.
  AnyProvider<T, R> get provider => _bind!.provider;

  /// Whether this [ProviderState] is bound.
  bool get mounted => _bind != null;

  @protected
  @mustCallSuper
  void initState() {}

  @protected
  @mustCallSuper
  void didUpdateProvider(covariant AnyProvider<T, R> oldProvider);

  @protected
  @mustCallSuper
  void activate() {}

  /// [State.deactivate]
  @protected
  @mustCallSuper
  void deactivate() {}

  @protected
  @mustCallSuper
  void reassemble() {}

  @protected
  @mustCallSuper
  void dispose() {}

  @protected
  R build(BuildContext context);
}
