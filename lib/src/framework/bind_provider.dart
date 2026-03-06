part of '../framework.dart';

@internal
@immutable
abstract class BindProvider<R> with Diagnosticable {
  const BindProvider({this.key});

  /// Controls how one provider replaces another in the bind tree.
  /// Similar to [Widget.key].
  final Object? key;

  /// A [Widget.canUpdate] implementation for [BindProvider] with [equals].
  static bool canUpdate(BindProvider oldProvider, BindProvider newProvider) {
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
  Bind<R> createBind();
}

@internal
sealed class Bind<R> extends LinkedListEntry<Bind> {
  Bind(BindProvider<R> provider) : _provider = provider;
  BindProvider<R>? _provider;
  Element? _element;
  ScopeIt? _scope;

  @visibleForTesting
  String get debugLabel;

  @protected
  Element get element => _element!;

  @protected
  BindProvider<R> get provider => _provider!;

  @internal
  ScopeIt get scope => _scope!;

  @mustCallSuper
  void update(covariant BindProvider<R> newProvider) {
    _provider = newProvider;
  }

  @mustCallSuper
  void bind() {}

  @mustCallSuper
  void activate() {}

  @mustCallSuper
  void deactivate() {}

  @mustCallSuper
  void reassemble() {}

  @mustCallSuper
  void unbind() {
    _provider = null;
  }

  R build();
}

extension ContextBind on BuildContext {
  R bind<R>(BindProvider<R> provider) {
    return ScopeIt.of(this).bind(this, provider);
  }
}

@internal
typedef Equals = bool Function(Object? a, Object? b);
