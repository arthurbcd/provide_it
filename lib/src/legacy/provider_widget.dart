part of '../legacy.dart';

sealed class ProviderWidget<T> extends Widget implements InheritedProvider<T> {
  const ProviderWidget({super.key, this.builder, this.child});

  final TransitionBuilder? builder;
  final Widget? child;

  @protected
  void bind(BuildContext context) {
    context.bind(this);
  }

  @override
  InheritedState<T, InheritedProvider<T>> createState();

  @override
  Bind<void> createBind() => InheritedBind(this);

  @override
  Element createElement() => _ProviderElement<T>(this);
}

class _ProviderElement<T> extends ComponentElement {
  _ProviderElement(super.widget);

  @override
  Widget build() {
    final provider = widget as ProviderWidget<T>;

    // we bind the provider to this context.
    provider.bind(this);

    return provider.builder?.call(this, provider.child) ?? provider.child!;
  }

  @override
  void update(ProviderWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }
}

@internal
abstract class ProviderlessWidget extends ProviderWidget<void> {
  const ProviderlessWidget({super.key, super.builder, super.child});

  @override
  @internal
  void bind(BuildContext context) {
    builder?.call(context, child);
  }

  @override
  InheritedState<void, InheritedProvider<void>> createState() {
    throw UnimplementedError();
  }
}
