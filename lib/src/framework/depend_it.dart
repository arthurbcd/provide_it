part of '../framework.dart';

mixin DependIt on InheritIt {
  @protected
  T dependOnInheritedProvider<T>(
    BuildContext context,
    InheritedAspect<T> aspect,
  ) {
    final bind = getInheritedBind<T>(context: context);
    if (bind == null) {
      if (null is T) return null as T;
      throw ProviderNotFoundException('$T not found.');
    }

    final node = context.dependOnInheritedNode(this);

    // bind handles self-dependency
    if (node.dependent != bind.dependent) {
      (node.dependencies ??= HashSet.identity()).add(bind);
    }

    return bind.depend(node.dependent, aspect);
  }
}

mixin Dependencies on NodeBase {
  // inherited binds that this node depends on
  Set<InheritedBind>? dependencies;

  @override
  void update() {
    super.update();
    if (dependencies != null) _clear();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (dependencies != null) _clear();
  }

  @override
  void reassemble() {
    super.reassemble();
    dependencies = null;
  }

  void _clear() {
    final dependencies = this.dependencies!;
    for (final bind in dependencies) {
      bind.removeDependent(dependent);
    }
    dependencies.clear();
  }
}
