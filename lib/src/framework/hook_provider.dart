part of '../framework.dart';

abstract class HookProvider<T> extends BindProvider<T> {
  const HookProvider({super.key});

  @protected
  HookState<T, HookProvider<T>> createState();

  @override
  Bind<T> createBind() => HookBind(this);
}

final class HookBind<T> extends Bind<T> {
  HookBind(HookProvider<T> super.provider) : _state = provider.createState() {
    state._bind = this;
  }
  HookState<T, HookProvider<T>>? _state;
  HookState<T, HookProvider<T>> get state => _state!;

  @override
  String get debugLabel => state.debugLabel;

  @override
  void bind() {
    state.initState();
    super.bind();
  }

  @override
  void update(HookProvider<T> newProvider) {
    final oldProvider = provider as HookProvider<T>;
    super.update(newProvider);
    state.didUpdateProvider(oldProvider);
  }

  @override
  void activate() {
    state.activate();
    super.activate();
  }

  @override
  void deactivate() {
    state.deactivate();
    super.deactivate();
  }

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void unbind() {
    state.dispose();
    super.unbind();
    _state = null;
  }

  @override
  T build() => state.build(element);
}

abstract class HookState<T, R extends HookProvider<T>> {
  HookBind<T>? _bind;

  @visibleForTesting
  String get debugLabel;

  @protected
  R get provider => _bind!.provider as R;

  @protected
  BuildContext get context => _bind!.element;

  @mustCallSuper
  void didUpdateProvider(covariant R oldProvider) {}

  @mustCallSuper
  void setState(VoidCallback fn) {
    fn();
    _bind!._element!.markNeedsBuild();
  }

  @mustCallSuper
  void initState() {}

  @mustCallSuper
  void activate() {}

  @mustCallSuper
  void deactivate() {}

  @mustCallSuper
  void reassemble() {}

  @mustCallSuper
  void dispose() {}

  @protected
  T build(BuildContext context);
}
