import 'package:bs_mobile/src/core/routing/routes.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const AppText('API URL'),
            subtitle: const AppText('Configure server connection'),
            onTap: () => context.push(Routes.configurl),
          ),
          ListTile(
            leading: const Icon(Icons.nfc),
            title: const AppText('RFID Config'),
            subtitle: const AppText('Scanner device settings'),
            onTap: () => context.push(Routes.configRfid),
          ),
        ],
      ),
    );
  }
}
