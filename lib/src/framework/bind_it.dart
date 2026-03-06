part of '../framework.dart';

mixin BindIt on InheritedElement {
  final _binds = HashMap<BuildContext, Binds>();
  final _inactiveBinds = HashSet<Bind>();
  HashSet<Bind>? _reassembledBinds;
  Binds? _currentBinds;

  @protected
  R bind<R>(BuildContext context, BindProvider<R> provider) {
    assert(
      // e.g. ListView.builder, SliverList.builder
      context is! RenderSliverBoxChildManager,
      'Cannot bind a provider to an unstable context: wrap it in a Builder or refactor it into its own widget to obtain a stable context.',
    );

    final Binds binds;

    if (_currentBinds?.context == context) {
      binds = _currentBinds!;
      binds.current = binds.current?.next;
    } else {
      binds = _currentBinds = _binds[context] ??= Binds(context);
      binds.current = binds.firstOrNull;
    }

    Bind<R> create() {
      final bind = provider.createBind()
        .._element = context as Element
        .._scope = this as ScopeIt
        ..bind();

      binds.add(bind);

      return bind;
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

      final newBind = provider.createBind()
        .._element = context as Element
        .._scope = this as ScopeIt
        ..bind();

      bind.insertBefore(newBind);
      bind.unlink();
      binds.current = newBind;

      return newBind;
    }

    bool canUpdate(Bind<R> bind) {
      return BindProvider.canUpdate(bind.provider, provider);
    }

    final bind = switch (binds.current) {
      null => create(),
      Bind<R> bind when canUpdate(bind) => update(bind),
      _ => replace(binds.current!), // reassembled or key changed
    };

    context.dependOnInheritedElement(this);

    return bind.build();
  }

  void _deactivateBind(Bind bind) {
    if (_inactiveBinds.add(bind)) {
      bind.deactivate();
    }
  }

  @override
  void removeDependent(Element dependent) {
    _binds[dependent]?.forEach(_deactivateBind);
    super.removeDependent(dependent);

    markDirty();
  }

  int _frame = 0;
  bool _dirty = false;

  void markDirty() {
    if (_dirty) return;
    _dirty = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _frame++;
      finalizeTree();
      _dirty = false;
    });
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
      // we check as it may be replaced by a new bind in the same entry.
      if (bind.list case final Binds binds) {
        bind.unlink();
        if (binds.isEmpty) _binds.remove(binds.context);
      }

      bind
        ..unbind()
        .._scope = null
        .._element = null;
    }

    _inactiveBinds.clear();
    _currentBinds = null;
  }

  @override
  void unmount() {
    finalizeTree();
    super.unmount();
  }

  @override
  void reassemble() {
    assert(() {
      _reassembledBinds ??= HashSet();
      _binds.forEach((_, binds) {
        for (var bind in binds) {
          // reassembled providers should update, otherwise we deactivate it.
          _reassembledBinds?.add(bind..reassemble());
        }
      });
      return true;
    }());
    super.reassemble();
  }
}

final class Binds extends LinkedList<Bind> {
  Binds(BuildContext context) : context = context as Element;
  final Element context;
  Bind? current;

  Bind? get firstOrNull => isEmpty ? null : first;
}
