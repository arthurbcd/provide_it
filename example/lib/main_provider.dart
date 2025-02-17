import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    Provider.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    context.read();
    return const Placeholder();
  }
}
