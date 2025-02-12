part of '../framework.dart';

abstract class RefWidget<T> extends Widget implements Ref<T> {
  const RefWidget({
    Object? key,
    this.builder,
    this.child,
  })  : _key = key,
        super(key: null);

  final TransitionBuilder? builder;
  final Widget? child;
  final Object? _key;

  @override
  Key? get key => _key is Key ? _key as Key : ObjectKey(_key);

  @override
  void bind(BuildContext context) => context.bind(this);

  @override
  Element createElement() => _RefElement(this);
}

class _RefElement extends ComponentElement {
  _RefElement(super.widget);

  @override
  RefWidget get widget => super.widget as RefWidget;

  @override
  Widget build() {
    assert(widget.builder != null || widget.child != null);

    widget.bind(this);
    return widget.builder?.call(this, widget.child) ?? widget.child!;
  }

  @override
  void update(RefWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }
}
