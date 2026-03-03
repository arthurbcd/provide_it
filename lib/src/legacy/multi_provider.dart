part of '../legacy.dart';

@Deprecated('Use multiple `context.provide` instead.')
class MultiProvider extends ProviderlessWidget {
  const MultiProvider({
    super.key,
    required this.providers,
    super.builder,
    super.child,
  }) : assert(child != null || builder != null);

  /// The providers to provide.
  final List<ProviderWidget> providers;

  @override
  void bind(BuildContext context) {
    for (final provider in providers) {
      provider.bind(context);
    }
  }
}
