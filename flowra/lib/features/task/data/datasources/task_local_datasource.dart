import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getCachedTasks();
  Future<void> cacheTasks(List<TaskModel> tasks);
}

const _kCachedTasksKey = 'cached_tasks';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final SharedPreferences prefs;

  TaskLocalDataSourceImpl({required this.prefs});

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    final jsonString = prefs.getString(_kCachedTasksKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final jsonString = json.encode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_kCachedTasksKey, jsonString);
  }
}
