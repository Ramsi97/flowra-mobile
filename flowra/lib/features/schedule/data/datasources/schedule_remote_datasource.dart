import '../../../../core/constants/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../model/schedule_item_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleItemModel>> generateSchedule(String date);
  Future<List<ScheduleItemModel>> regenerateSchedule(String date);
  Future<List<ScheduleItemModel>> updateItem(
      String itemId, Map<String, dynamic> updates);
  Future<void> deleteItem(String itemId);
  Future<void> clearDay(String date);
  Future<void> clearWeek(String startDate);
  Future<void> clearMonth(String month);
  Future<List<ScheduleItemModel>> fixSchedule(String currentTime);
  Future<void> removeTaskFromSchedule(String itemId);
  Future<List<ScheduleItemModel>> aiSchedule(String date, String prompt);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final ApiClient apiClient;

  ScheduleRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ScheduleItemModel>> generateSchedule(String date) async {
    final response =
        await apiClient.post(Endpoints.generateSchedule, {'date': date});
    if (response == null) return [];
    return ScheduleItemModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<List<ScheduleItemModel>> regenerateSchedule(String date) async {
    final response =
        await apiClient.post(Endpoints.regenerateSchedule, {'date': date});
    if (response == null) return [];
    return ScheduleItemModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<List<ScheduleItemModel>> updateItem(
      String itemId, Map<String, dynamic> updates) async {
    final response = await apiClient.put(Endpoints.scheduleItem(itemId), updates);
    if (response == null) return [];
    return ScheduleItemModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await apiClient.delete(Endpoints.scheduleItem(itemId));
  }

  @override
  Future<void> clearDay(String date) async {
    await apiClient.delete(Endpoints.clearDay(date));
  }

  @override
  Future<void> clearWeek(String startDate) async {
    await apiClient.delete(Endpoints.clearWeek(startDate));
  }

  @override
  Future<void> clearMonth(String month) async {
    await apiClient.delete(Endpoints.clearMonth(month));
  }

  @override
  Future<List<ScheduleItemModel>> fixSchedule(String currentTime) async {
    final response =
        await apiClient.post(Endpoints.fixSchedule, {'current_time': currentTime});
    if (response == null) return [];
    return ScheduleItemModel.fromJsonList(response as List<dynamic>);
  }

  @override
  Future<void> removeTaskFromSchedule(String itemId) async {
    await apiClient.delete(Endpoints.removeTask(itemId));
  }

  @override
  Future<List<ScheduleItemModel>> aiSchedule(
      String date, String prompt) async {
    final response = await apiClient.post(Endpoints.aiSchedule, {
      'date': date,
      'prompt': prompt,
    });
    if (response == null) return [];
    return ScheduleItemModel.fromJsonList(response as List<dynamic>);
  }
}
