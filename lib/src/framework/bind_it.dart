part of '../framework.dart';

mixin BindIt on InheritIt {
  /// The attached [ProvideIt] element.
  ProvideItElement? _element;

  // bind tree by context & index.
  final _binds = HashMap<Element, HashMap<int, Bind>>();
  final _bindIndex = HashMap<Element, int>();

  final _inactiveBinds = HashSet<Bind>();
  HashSet<Bind>? _reassembledBinds;

  @protected
  R bind<R>(BuildContext context, BindProvider<R> provider) {
    assert(
      // e.g. ListView.builder, SliverList.builder
      context is! RenderSliverBoxChildManager,
      'Cannot bind a provider to an unstable context: wrap it in a Builder or refactor it into its own widget to obtain a stable context.',
    );

    final binds = _binds[context as Element] ??= HashMap();
    final index = _bindIndex[context] ??= 0;
    _bindIndex[context] = index + 1; // next provider index

    Bind<R> create() {
      return binds[index] = provider.createBind()
        .._element = context
        .._index = index
        .._owner = this
        ..bind();
    }

    Bind<R> update(Bind<R> bind) {
      assert(() {
        _reassembledBinds?.remove(bind);
        return true;
      }());

      if (_inactiveBinds.remove(bind)) {
        bind.activate();
      }

      return bind..update(provider);
    }

    Bind<R> replace(Bind bind) {
      assert(() {
        final reassembled = _reassembledBinds?.remove(bind) == true;
        return reassembled || bind.provider.runtimeType == provider.runtimeType;
      }(), 'Provider must be reassembled or key changed to replace.');

      _deactivateBind(bind);

      return create();
    }

    bool canUpdate(Bind<R> bind) {
      return BindProvider.canUpdate(bind.provider, provider);
    }

    final bind = switch (binds[index]) {
      null => create(),
      Bind<R> bind when canUpdate(bind) => update(bind),
      final bind => replace(bind), // reassembled or key changed
    };

    context.dependOnInheritedElement(_element!);

    return bind.build();
  }

  void _deactivateBind(Bind bind) {
    if (_inactiveBinds.add(bind)) {
      bind.deactivate();
    }
  }

  @internal
  void deactivateBinds(BuildContext context) {
    _binds[context]?.forEach((_, bind) => _deactivateBind(bind));
  }

  @internal
  void finalizeTree() {
    assert(() {
      // removed after reassemble, we deactivate/dispose it.
      _reassembledBinds?.forEach(_deactivateBind);
      _reassembledBinds?.clear();
      return true;
    }());

    for (var bind in _inactiveBinds) {
      final binds = _binds[bind.element]!;

      // we check as it may be replaced by a new bind with the same index.
      if (binds[bind.index] == bind) {
        binds.remove(bind.index);
        if (binds.isEmpty) _binds.remove(bind.element);
      }

      bind
        ..unbind()
        .._owner = null
        .._index = null
        .._element = null;
    }

    _inactiveBinds.clear();
    _bindIndex.clear();
  }

  @internal
  void reassembleTree() {
    assert(() {
      _reassembledBinds ??= HashSet();
      _binds.forEach((_, binds) {
        binds.forEach((_, bind) {
          // reassembled providers should update, otherwise we deactivate it.
          _reassembledBinds?.add(bind..reassemble());
        });
      });
      return true;
    }());
  }
}
