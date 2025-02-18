import 'package:flutter/widgets.dart';
import 'package:provide_it/src/core.dart';

@Deprecated('Use `context.watch` instead.')
class Consumer<T> extends StatelessWidget {
  const Consumer({super.key, this.builder, this.child});
  final Widget Function(BuildContext context, T value, Widget? child)? builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return builder?.call(context, context.watch(), child) ?? child!;
  }
}
