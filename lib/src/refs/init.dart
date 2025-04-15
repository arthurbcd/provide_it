import 'package:flutter/widgets.dart';
import 'package:provide_it/src/framework.dart';
import 'package:provide_it/src/refs/ref.dart';

class InitRef extends Ref<void> {
  const InitRef({this.init, this.dispose, super.key});
  final VoidCallback? init;
  final VoidCallback? dispose;

  @override
  Function? get create => init;

  @override
  Bind<void, Ref<void>> createBind() => InitBind();
}

class InitBind extends Bind<void, InitRef> {
  @override
  void initBind() {
    ref.init?.call();
    super.initBind();
  }

  @override
  void dispose() {
    ref.dispose?.call();
    super.dispose();
  }

  @override
  void value;
}
