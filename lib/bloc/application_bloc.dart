// lib/bloc/application_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/job_application.dart';
import 'package:gig_marketplace/repositories/application_repository.dart';

// Events
abstract class ApplicationEvent {}

class LoadAppliedJobsEvent extends ApplicationEvent {
  final String employeeId;

  LoadAppliedJobsEvent({required this.employeeId});
}

class LoadJobApplicantsEvent extends ApplicationEvent {
  final String jobId;

  LoadJobApplicantsEvent({required this.jobId});
}

class ApplyForJobEvent extends ApplicationEvent {
  final String jobId;
  final String employeeId;
  final String? coverLetter;

  ApplyForJobEvent({
    required this.jobId,
    required this.employeeId,
    this.coverLetter,
  });
}

class UpdateApplicationStatusEvent extends ApplicationEvent {
  final String applicationId;
  final ApplicationStatus newStatus;

  UpdateApplicationStatusEvent({
    required this.applicationId,
    required this.newStatus,
  });
}

// States
abstract class ApplicationState {}

class ApplicationInitial extends ApplicationState {}

class ApplicationLoading extends ApplicationState {}

class AppliedJobsLoaded extends ApplicationState {
  final List<JobApplication> applications;

  AppliedJobsLoaded({required this.applications});
}

class JobApplicantsLoaded extends ApplicationState {
  final List<JobApplication> applicants;

  JobApplicantsLoaded({required this.applicants});
}

class ApplicationSuccess extends ApplicationState {
  final String message;

  ApplicationSuccess({required this.message});
}

class ApplicationError extends ApplicationState {
  final String message;

  ApplicationError({required this.message});
}

// BLoC
class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  final ApplicationRepository applicationRepository;

  ApplicationBloc({required this.applicationRepository}) : super(ApplicationInitial()) {
    on<LoadAppliedJobsEvent>(_onLoadAppliedJobs);
    on<LoadJobApplicantsEvent>(_onLoadJobApplicants);
    on<ApplyForJobEvent>(_onApplyForJob);
    on<UpdateApplicationStatusEvent>(_onUpdateApplicationStatus);
  }

  Future<void> _onLoadAppliedJobs(LoadAppliedJobsEvent event, Emitter<ApplicationState> emit) async {
    emit(ApplicationLoading());
    try {
      final applications = await applicationRepository.getAppliedJobs(employeeId: event.employeeId);
      emit(AppliedJobsLoaded(applications: applications));
    } catch (e) {
      emit(ApplicationError(message: e.toString()));
    }
  }

  Future<void> _onLoadJobApplicants(LoadJobApplicantsEvent event, Emitter<ApplicationState> emit) async {
    emit(ApplicationLoading());
    try {
      final applicants = await applicationRepository.getJobApplicants(jobId: event.jobId);
      emit(JobApplicantsLoaded(applicants: applicants));
    } catch (e) {
      emit(ApplicationError(message: e.toString()));
    }
  }

  Future<void> _onApplyForJob(ApplyForJobEvent event, Emitter<ApplicationState> emit) async {
    emit(ApplicationLoading());
    try {
      await applicationRepository.applyForJob(
        jobId: event.jobId,
        employeeId: event.employeeId,
        coverLetter: event.coverLetter,
      );
      emit(ApplicationSuccess(message: 'Application submitted successfully'));
    } catch (e) {
      emit(ApplicationError(message: e.toString()));
    }
  }

  Future<void> _onUpdateApplicationStatus(UpdateApplicationStatusEvent event, Emitter<ApplicationState> emit) async {
    emit(ApplicationLoading());
    try {
      await applicationRepository.updateApplicationStatus(
        applicationId: event.applicationId,
        newStatus: event.newStatus,
      );
      emit(ApplicationSuccess(message: 'Application status updated successfully'));
    } catch (e) {
      emit(ApplicationError(message: e.toString()));
    }
  }
}