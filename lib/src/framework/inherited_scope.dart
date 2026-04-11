part of '../framework.dart';

sealed class InheritedScope extends InheritedElement {
  InheritedScope(super.widget);
  final _nodes = HashMap<Element, Node>();
  final _inactiveNodes = <Node>[];

  Node? _currentNode;
  Node? get currentNode => _currentNode;

  @protected
  @mustCallSuper
  void finalizeTree() {
    final length = _inactiveNodes.length;

    for (var i = 0; i < length; i++) {
      final node = _inactiveNodes[i];
      if (!node.deactivated) continue; // reactivated

      _nodes.remove(node.dependent)
        ?..finalize()
        .._scope = null;
    }

    _inactiveNodes.clear();
    _currentNode = null;
  }

  @override
  void updateDependencies(Element dependent, _) {
    if (_currentNode == null && _inactiveNodes.isEmpty) {
      scheduleMicrotask(finalizeTree);
    }

    _currentNode = switch (_nodes[dependent]) {
      null => _nodes[dependent] = Node(dependent).._scope = this,
      final node => node..update(),
    };
  }

  @override
  void removeDependent(Element dependent) {
    if (_currentNode == null && _inactiveNodes.isEmpty) {
      scheduleMicrotask(finalizeTree);
    }

    final node = _nodes[dependent]!;
    _inactiveNodes.add(node..deactivate());

    super.removeDependent(dependent);
  }

  @override
  void reassemble() {
    _nodes.forEach((_, node) => node.reassemble());
    super.reassemble();
  }

  @override
  void unmount() {
    finalizeTree();
    super.unmount();
  }
}

extension on BuildContext {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  Node dependOnInheritedNode(InheritedScope ancestor) {
    if (!identical(ancestor._currentNode?.dependent, this)) {
      dependOnInheritedElement(ancestor);
    }

    return ancestor._currentNode!;
  }
}

abstract class NodeBase {
  NodeBase(this.dependent);
  final Element dependent;

  InheritedScope? _scope;
  InheritedScope get scope => _scope!;

  @mustCallSuper
  void update() {}

  @mustCallSuper
  void deactivate() {}

  @mustCallSuper
  void reassemble() {}

  @mustCallSuper
  void finalize() {}
}
