part of 'framework.dart';

abstract class RefWidget<T> extends Widget implements Ref<T> {
  const RefWidget({
    super.key,
    this.builder,
    this.child,
  });

  final TransitionBuilder? builder;
  final Widget? child;

  @override
  String get type => T.toString();

  @override
  void bind(BuildContext context) => context.bind(this);

  @override
  Element createElement() => RefElement(this);
}

class RefElement extends ComponentElement {
  RefElement(super.widget);

  @override
  RefWidget get widget => super.widget as RefWidget;

  @override
  Widget build() {
    assert(widget.builder != null || widget.child != null);

    /// we bind the reference to its own element.
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
