import 'package:flutter/widgets.dart';
import 'package:provide_it/provide_it.dart';

abstract class RefWidget<T> extends Widget implements Ref<T> {
  const RefWidget({
    super.key,
    this.builder,
    this.child,
    Dispose<T>? dispose,
  }) : _dispose = dispose;

  final TransitionBuilder? builder;
  final Widget? child;

  // Disposing with deactivated context is only possible with a RefWidget.
  final Dispose<T>? _dispose;

  @override
  Element createElement() => RefElement<T>(this);
}

class RefElement<T> extends ComponentElement {
  RefElement(super.widget);
  RefState<T, Ref<T>>? _state;

  @override
  RefWidget<T> get widget => super.widget as RefWidget<T>;

  @override
  Widget build() {
    assert(widget.builder != null || widget.child != null);

    // we bind it to its own element.
    _state = widget.bind(this);

    return widget.builder?.call(this, widget.child) ?? widget.child!;
  }

  @override
  void update(RefWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    // to mimic `provider`, we must callback the inactive context.
    // still can't access ancestors, but `context.widget` works.
    if (_state!.value case T value) {
      widget._dispose?.call(this, value);
    }
    super.unmount();
    _state = null;
  }
}
