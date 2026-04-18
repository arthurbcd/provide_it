part of '../framework.dart';

mixin BindIt on InheritedScope {
  final _inactiveBinds = <Bind>[];
  Set<Bind>? _reassembledBinds;

  @protected
  R bind<R>(BuildContext context, BindProvider<R> provider) {
    final node = context.dependOnInheritedScope(this);
    final binds = node.binds ??= Binds();
    final Bind<R> bind;

    switch (binds.current) {
      case null:
        bind = provider.createBind()
          .._node = node
          ..bind();

        binds.add(bind);

      case Bind<R> oldBind when Bind.canUpdate(oldBind.provider, provider):
        assert(_reassembledBinds?.remove(oldBind) != false);
        bind = oldBind..update(provider);

      case final oldBind:
        assert(
          oldBind.provider.runtimeType == provider.runtimeType || // key changed
              _reassembledBinds?.remove(oldBind) == true, // reassembled
          'Provider must be reassembled or key changed to replace.',
        );
        _inactiveBinds.add(oldBind..deactivate());

        bind = provider.createBind()
          .._node = node
          ..bind();

        binds.replace(bind);
    }
    binds.next();

    return bind.build();
  }

  @override
  void finalizeTree() {
    for (var i = 0; i < _inactiveBinds.length; i++) {
      _unbind(_inactiveBinds[i]);
    }
    _inactiveBinds.clear();

    assert(() {
      final orphans = _reassembledBinds;
      if (orphans == null) return true;

      for (var bind in orphans) {
        if (bind.list!.length == 1) {
          removeDependent(bind.dependent);
          continue;
        }
        bind.unlink();
        _unbind(bind..deactivate());
      }
      _reassembledBinds = null;
      return true;
    }());

    super.finalizeTree();
  }

  static void _unbind(Bind bind) => bind
    ..unbind()
    .._node = null;
}

final class Binds extends LinkedList<Bind> {
  Bind? _current;
  Bind? get current => _current;

  @override
  void add(Bind entry) => super.add(_current = entry);
  void next() => _current = _current?.next;
  void replace(Bind newEntry) {
    _current!
      ..insertBefore(newEntry)
      ..unlink();
    _current = newEntry;
  }

  Bind? reset() => _current = isEmpty ? null : first;
}

mixin Bindings on NodeBase {
  Binds? binds;
  bool deactivated = false;

  @override
  ScopeIt get scope => super.scope as ScopeIt;

  @override
  void update() {
    super.update();
    var bind = binds?.reset();
    if (!deactivated) return;
    for (; bind != null; bind = bind.next) {
      bind.activate();
    }
    deactivated = false;
  }

  @override
  void deactivate() {
    super.deactivate();
    if (binds == null) return;
    for (var bind = binds?.first; bind != null; bind = bind.next) {
      bind.deactivate();
    }
    deactivated = true;
  }

  @override
  void reassemble() {
    super.reassemble();
    if (binds == null) return;
    for (var bind = binds?.first; bind != null; bind = bind.next) {
      final reassembled = scope._reassembledBinds ??= HashSet();
      reassembled.add(bind..reassemble());
    }
  }

  @override
  void finalize() {
    super.finalize();
    if (binds == null) return;
    for (var bind = binds?.first; bind != null; bind = bind.next) {
      BindIt._unbind(bind);
    }
  }
}
