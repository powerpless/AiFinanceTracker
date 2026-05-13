import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currencyProvider);
    final controller = ref.read(currencyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: RadioGroup<Currency>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) controller.setCurrency(v);
        },
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Валюта',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...Currency.values.map((c) {
              return RadioListTile<Currency>(
                value: c,
                title: Text('${c.name} (${c.symbol})'),
                subtitle: Text(c.code),
              );
            }),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Выбор валюты влияет только на отображение знака валюты. '
                'Транзакции хранятся в числовом виде без конвертации.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
