import '../../../../core/network/api_client.dart';
import '../model/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(String id, Map<String, dynamic> updates);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> suggestTasks(String description);
  Future<List<TaskModel>> refineTasks(List<TaskModel> drafts, String instruction);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient apiClient;

  TaskRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TaskModel>> getTasks() async {
    final response = await apiClient.get('/tasks');
    if (response == null) return [];
    return TaskModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    final response = await apiClient.post('/tasks', task.toJson());
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TaskModel> updateTask(String id, Map<String, dynamic> updates) async {
    final response = await apiClient.put('/tasks/$id', updates);
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTask(String id) async {
    await apiClient.delete('/tasks/$id');
  }

  @override
  Future<List<TaskModel>> suggestTasks(String description) async {
    final response = await apiClient.post('/tasks/suggest', {
      'description': description,
    });
    if (response == null) return [];
    return TaskModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<List<TaskModel>> refineTasks(List<TaskModel> drafts, String instruction) async {
    final response = await apiClient.post('/tasks/refine', {
      'drafts': drafts.map((e) => e.toJson()).toList(),
      'instruction': instruction,
    });
    if (response == null) return [];
    return TaskModel.fromJsonList(response as List<dynamic>);
  }
}
