part of '../framework.dart';

@immutable
abstract class BindProvider<R> with Diagnosticable {
  const BindProvider({this.key});

  /// Like [Widget.key].
  /// Controls how one provider replaces another in the bind tree.
  final Object? key;

  @protected
  Bind<R> createBind();
}

@internal
sealed class Bind<R> extends LinkedListEntry<Bind> {
  /// Like [Widget.canUpdate].
  static bool canUpdate(BindProvider oldProvider, BindProvider newProvider) {
    return oldProvider.runtimeType == newProvider.runtimeType &&
        ProvideIt.equals(oldProvider.key, newProvider.key);
  }

  Bind(BindProvider<R> provider) : _provider = provider;
  BindProvider<R>? _provider;
  Node? _node;

  @visibleForTesting
  String get debugLabel;

  @protected
  ScopeIt get scope => _node!.scope;

  @protected
  Element get dependent => _node!.dependent;

  @protected
  BindProvider<R> get provider => _provider!;

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
    final scope = ScopeIt.of(this);
    assert(
      // e.g. ListView.builder, SliverList.builder
      this is! RenderSliverBoxChildManager,
      'Cannot bind a provider to an unstable context: wrap it in a Builder or refactor it into its own widget to obtain a stable context.',
    );
    return scope.bind(this, provider);
  }
}
