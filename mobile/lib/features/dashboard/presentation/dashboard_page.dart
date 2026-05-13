import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дашборд')),
      body: const DashboardScreen(),
    );
  }
}
