part of '../legacy.dart';

@Deprecated('Use `Builder` with `context.watch` instead.')
class Consumer<T> extends ProviderlessWidget {
  Consumer({
    super.key,
    super.child,
    Widget builder(BuildContext context, T value, Widget? child)?,
  }) : super(builder: (context, child) {
          return builder?.call(context, context.watch(), child) ?? child!;
        });
}

@Deprecated('Use `Builder` with multiple `context.watch` instead.')
class Consumer2<A, B> extends ProviderlessWidget {
  Consumer2({
    super.key,
    super.child,
    Widget builder(BuildContext context, A a, B b, Widget? child)?,
  }) : super(builder: (context, child) {
          final $ = context.watch;
          return builder?.call(context, $(), $(), child) ?? child!;
        });
}

@Deprecated('Use `Builder` with multiple `context.watch` instead.')
class Consumer3<A, B, C> extends ProviderlessWidget {
  Consumer3({
    super.key,
    super.child,
    Widget builder(BuildContext context, A a, B b, C c, Widget? child)?,
  }) : super(builder: (context, child) {
          final $ = context.watch;
          return builder?.call(context, $(), $(), $(), child) ?? child!;
        });
}

@Deprecated('Use `Builder` with multiple `context.watch` instead.')
class Consumer4<A, B, C, D> extends ProviderlessWidget {
  Consumer4({
    super.key,
    super.child,
    Widget builder(BuildContext context, A a, B b, C c, D d, Widget? child)?,
  }) : super(builder: (context, child) {
          final $ = context.watch;
          return builder?.call(context, $(), $(), $(), $(), child) ?? child!;
        });
}

@Deprecated('Use `Builder` with multiple `context.watch` instead.')
class Consumer5<A, B, C, D, E> extends ProviderlessWidget {
  Consumer5({
    super.key,
    super.child,
    Widget builder(
        BuildContext context, A a, B b, C c, D d, E e, Widget? child)?,
  }) : super(builder: (context, child) {
          final $ = context.watch;
          return builder?.call(context, $(), $(), $(), $(), $(), child) ??
              child!;
        });
}

@Deprecated('Use `Builder` with multiple `context.watch` instead.')
class Consumer6<A, B, C, D, E, F> extends ProviderlessWidget {
  Consumer6({
    super.key,
    super.child,
    Widget builder(
        BuildContext context, A a, B b, C c, D d, E e, F f, Widget? child)?,
  }) : super(builder: (context, child) {
          final $ = context.watch;
          return builder?.call(context, $(), $(), $(), $(), $(), $(), child) ??
              child!;
        });
}
