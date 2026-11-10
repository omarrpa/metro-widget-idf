// Metro Widget IDF - rafraîchissement en arrière-plan (WorkManager / BGTask) et tap sur le widget
// Créé par : Omar Pérez - 2026-11-09 08:10
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'board_service.dart';
import 'config.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    await HomeWidget.setAppGroupId(AppConfig.appGroupId);
    await BoardService.refreshAndPush(background: true);
    return true;
  });
}

@pragma('vm:entry-point')
Future<void> widgetTapped(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId(AppConfig.appGroupId);
  if (uri?.host == 'refresh') {
    await BoardService.refreshAndPush(background: true);
  }
}

Future<void> initBackground() async {
  await HomeWidget.setAppGroupId(AppConfig.appGroupId);
  await HomeWidget.registerInteractivityCallback(widgetTapped);
  try {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      AppConfig.bgTask,
      AppConfig.bgTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    debugPrint('Workmanager indisponible : $e');
  }
}
