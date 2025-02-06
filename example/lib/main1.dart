import 'package:flutter/material.dart';
import 'package:provider_plus/provider_plus.dart';

class MeuContador extends StatefulWidget {
  const MeuContador({super.key});

  @override
  State<MeuContador> createState() => _MeuContadorState();
}

class _MeuContadorState extends State<MeuContador> {
  final count = ValueNotifier(0);

  void listener() {
    setState(() {});
  }

  @override
  void initState() {
    count.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    count.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        count.value++;
      },
      child: Text('Contagem: ${count.value}'),
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.useState(0);

    return ElevatedButton(
      onPressed: () {
        count.value = count.value + 1;
      },
      child: Text('Contagem: ${count.value}'),
    );
  }
}

class AnimationExample extends StatefulWidget {
  const AnimationExample({super.key});

  @override
  State<AnimationExample> createState() => _AnimationExampleState();
}

class _AnimationExampleState extends State<AnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Inicializa o AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duração da animação
    );

    // Define a curva da animação
    _animation = Tween<double>(begin: 100.0, end: 300.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Inicia a animação em loop
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera os recursos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Animation Example')),
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: _animation.value,
              height: _animation.value,
              color: Colors.blue,
            );
          },
        ),
      ),
    );
  }
}

class AnimationExample2 extends StatelessWidget {
  const AnimationExample2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.useAnimationController(
      duration: Duration(seconds: 2),
      lowerBound: 100.0,
      upperBound: 300.0,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Flutter Animation Example')),
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Container(
              width: controller.value,
              height: controller.value,
              color: Colors.blue,
            );
          },
        ),
      ),
    );
  }
}
