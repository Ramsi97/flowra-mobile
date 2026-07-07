import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleItem>>> generateSchedule(String date);
  Future<Either<Failure, List<ScheduleItem>>> regenerateSchedule(String date);
  Future<Either<Failure, List<ScheduleItem>>> updateItem(
    String itemId,
    Map<String, dynamic> updates,
  );
  Future<Either<Failure, void>> deleteItem(String itemId);
  Future<Either<Failure, void>> clearDay(String date);
  Future<Either<Failure, void>> clearWeek(String startDate);
  Future<Either<Failure, void>> clearMonth(String month);
  Future<Either<Failure, List<ScheduleItem>>> fixSchedule(String currentTime);
  Future<Either<Failure, void>> removeTaskFromSchedule(String itemId);
  Future<Either<Failure, List<ScheduleItem>>> aiSchedule(
    String date,
    String prompt,
  );
}
