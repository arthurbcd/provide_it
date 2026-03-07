part of '../framework.dart';

mixin BindIt on InheritedElement {
  final _nodes = HashMap<BuildContext, Node>();
  // final _binds = HashMap<BuildContext, Binds>();
  final _inactiveBinds = HashSet<Bind>();
  HashSet<Bind>? _reassembledBinds;
  Node? _currentNode;

  void changeNode(Node? prev, Node next) {
    next.binds?.reset();
  }

  @protected
  R bind<R>(BuildContext context, BindProvider<R> provider) {
    assert(
      // e.g. ListView.builder, SliverList.builder
      context is! RenderSliverBoxChildManager,
      'Cannot bind a provider to an unstable context: wrap it in a Builder or refactor it into its own widget to obtain a stable context.',
    );

    final node = context.dependOnScope(this);
    final binds = node.binds ??= Binds();

    Bind<R> create() {
      final bind = provider.createBind()
        .._element = node.dependent
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
        .._element = bind.element
        .._scope = bind.scope
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

    binds.next();

    return bind.build();
  }

  void _deactivateBind(Bind bind) {
    if (_inactiveBinds.add(bind)) {
      bind.deactivate();
    }
  }

  void deactivateNode(Node node) {
    if (node.binds case final Binds binds) {
      binds.forEach(_deactivateBind);
    } else {
      _nodes.remove(node.dependent);
    }
  }

  bool _dirty = false;

  void markDirty() {
    if (_dirty) return;
    _dirty = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        if (binds.isEmpty) _nodes.remove(bind.element);
      }

      bind
        ..unbind()
        .._scope = null
        .._element = null;
    }

    _inactiveBinds.clear();
    _currentNode = null;
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
      _nodes.forEach((_, node) {
        if (node.binds case final Binds binds) {
          for (var bind in binds) {
            // reassembled providers should update, otherwise we deactivate it.
            _reassembledBinds?.add(bind..reassemble());
          }
        }
      });
      return true;
    }());
    super.reassemble();
  }
}

extension on BuildContext {
  /// Calls [ScopeIt.updateDependencies] which sets the current [Node].
  Node dependOnScope(BindIt scope) {
    dependOnInheritedElement(scope);
    return scope._currentNode!;
  }
}

final class Binds extends LinkedList<Bind> {
  Bind? current;
  @override
  void add(Bind entry) => super.add(current = entry);
  void next() => current = current?.next;
  void reset() => current = isEmpty ? null : first;
}

mixin Bindings {
  Element get dependent;
  Binds? binds;
}
