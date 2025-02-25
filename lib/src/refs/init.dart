import 'package:flutter/widgets.dart';
import 'package:provide_it/src/framework.dart';
import 'package:provide_it/src/refs/ref.dart';

class InitRef extends Ref<void> {
  const InitRef({this.init, this.dispose, super.key});
  final VoidCallback? init;
  final VoidCallback? dispose;

  @override
  RefState<void, Ref<void>> createState() => InitRefState();
}

class InitRefState extends RefState<void, InitRef> {
  @override
  void initState() {
    ref.init?.call();
    super.initState();
  }

  @override
  void dispose() {
    ref.dispose?.call();
    super.dispose();
  }

  @override
  void create() {}

  @override
  void read() {}
}
