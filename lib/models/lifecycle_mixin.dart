import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

mixin LifecycleMixin<T extends StatefulWidget> on State<T> {
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
  }

  @override
  void dispose() {
    _mounted = false;
    SystemChannels.lifecycle.setMessageHandler(null);
    super.dispose();
  }

  Future<String?> _handleLifecycleMessage(String? message) async {
    if (!_mounted) return null;

    switch (message) {
      case 'AppLifecycleState.paused':
        // Handle app paused
        break;
      case 'AppLifecycleState.resumed':
        // Handle app resumed
        break;
      case 'AppLifecycleState.inactive':
        // Handle app inactive
        break;
      case 'AppLifecycleState.detached':
        // Handle app detached
        break;
    }
    return null;
  }
}
