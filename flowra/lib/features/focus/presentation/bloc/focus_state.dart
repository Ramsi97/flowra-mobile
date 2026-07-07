import 'package:equatable/equatable.dart';
import '../../domain/entities/focus_status.dart';

abstract class FocusState extends Equatable {
  const FocusState();
  @override
  List<Object?> get props => [];
}

class FocusInitial extends FocusState {
  const FocusInitial();
}

class FocusLoading extends FocusState {
  final FocusStatus? preserved;
  const FocusLoading({this.preserved});
  @override
  List<Object?> get props => [preserved];
}

class FocusLoaded extends FocusState {
  final FocusStatus status;
  const FocusLoaded(this.status);
  @override
  List<Object?> get props => [status];
}

class FocusError extends FocusState {
  final String message;
  final FocusStatus? preserved;
  const FocusError(this.message, {this.preserved});
  @override
  List<Object?> get props => [message, preserved];
}
