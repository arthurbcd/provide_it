part of '../framework.dart';

abstract class HookProvider<T> extends AnyProvider<T, T> {
  const HookProvider({super.key});

  @override
  HookState<T, HookProvider<T>> createState();
}

abstract class HookState<T, R extends HookProvider<T>>
    extends ProviderState<T, T> {
  @override
  R get provider => super.provider as R;

  @override
  @mustCallSuper
  void didUpdateProvider(covariant R oldProvider) {}

  @protected
  @mustCallSuper
  void setState(VoidCallback fn) {
    fn();
    _bind!.element.markNeedsBuild();
  }

  @override
  T build(BuildContext context);
}
