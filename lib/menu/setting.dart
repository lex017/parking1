import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          ListTile(
            title: const Text("Change Password"),
            leading: const Icon(Icons.lock),
            onTap: () {
              // Navigate to password change screen
            },
          ),
          ListTile(
            title: const Text("About App"),
            leading: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Parking App",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.local_parking),
                children: [
                  const Text("This is a parking management app.")
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}