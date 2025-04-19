// lib/bloc/job_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/repositories/job_repository.dart';

// Events
abstract class JobEvent {}

class LoadJobsEvent extends JobEvent {
  final Map<String, dynamic>? filters;

  LoadJobsEvent({this.filters});
}

class LoadEmployerJobsEvent extends JobEvent {
  final String employerId;
  final Map<String, dynamic>? filters;

  LoadEmployerJobsEvent({required this.employerId, this.filters});
}

class CreateJobEvent extends JobEvent {
  final String employerId;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String location;
  final bool isRemote;
  final DateTime deadline;
  final double? budget;
  final List<File>? mediaUrls;

  CreateJobEvent({
    required this.employerId,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.location,
    required this.isRemote,
    required this.deadline,
    this.budget,
    this.mediaUrls,
  });
}

class UpdateJobEvent extends JobEvent {
  final String jobId;
  final String? title;
  final String? description;
  final String? category;
  final List<String>? tags;
  final String? location;
  final bool? isRemote;
  final DateTime? deadline;
  final double? budget;
  final List<File>? mediaUrls;

  UpdateJobEvent({
    required this.jobId,
    this.title,
    this.description,
    this.category,
    this.tags,
    this.location,
    this.isRemote,
    this.deadline,
    this.budget,
    this.mediaUrls,
  });
}

class DeleteJobEvent extends JobEvent {
  final String jobId;

  DeleteJobEvent({required this.jobId});
}

class LoadJobDetailsEvent extends JobEvent {
  final String jobId;

  LoadJobDetailsEvent({required this.jobId});
}

// States
abstract class JobState {}

class JobInitial extends JobState {}

class JobLoading extends JobState {}

class JobsLoaded extends JobState {
  final List<Job> jobs;

  JobsLoaded({required this.jobs});
}

class JobDetailsLoaded extends JobState {
  final Job job;

  JobDetailsLoaded({required this.job});
}

class JobOperationSuccess extends JobState {
  final String message;
  
  JobOperationSuccess({required this.message});
}

class JobError extends JobState {
  final String message;

  JobError({required this.message});
}

// BLoC
class JobBloc extends Bloc<JobEvent, JobState> {
  final JobRepository jobRepository;

  JobBloc({required this.jobRepository}) : super(JobInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<LoadEmployerJobsEvent>(_onLoadEmployerJobs);
    on<CreateJobEvent>(_onCreateJob);
    on<UpdateJobEvent>(_onUpdateJob);
    on<DeleteJobEvent>(_onDeleteJob);
    on<LoadJobDetailsEvent>(_onLoadJobDetails);
  }

  Future<void> _onLoadJobs(LoadJobsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final jobs = await jobRepository.getJobs(filters: event.filters);
      emit(JobsLoaded(jobs: jobs));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }

  Future<void> _onLoadEmployerJobs(LoadEmployerJobsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final jobs = await jobRepository.getEmployerJobs(
        employerId: event.employerId,
        filters: event.filters,
      );
      emit(JobsLoaded(jobs: jobs));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }

  Future<void> _onCreateJob(CreateJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      await jobRepository.createJob(
        employerId: event.employerId,
        title: event.title,
        description: event.description,
        category: event.category,
        tags: event.tags,
        location: event.location,
        isRemote: event.isRemote,
        deadline: event.deadline,
        budget: event.budget,
        mediaUrls: event.mediaUrls,
      );
      emit(JobOperationSuccess(message: 'Job created successfully'));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }

  Future<void> _onUpdateJob(UpdateJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      await jobRepository.updateJob(
        jobId: event.jobId,
        title: event.title,
        description: event.description,
        category: event.category,
        tags: event.tags,
        location: event.location,
        isRemote: event.isRemote,
        deadline: event.deadline,
        budget: event.budget,
        mediaUrls: event.mediaUrls,
      );
      emit(JobOperationSuccess(message: 'Job updated successfully'));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }

  Future<void> _onDeleteJob(DeleteJobEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      await jobRepository.deleteJob(jobId: event.jobId);
      emit(JobOperationSuccess(message: 'Job deleted successfully'));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }

  Future<void> _onLoadJobDetails(LoadJobDetailsEvent event, Emitter<JobState> emit) async {
    emit(JobLoading());
    try {
      final job = await jobRepository.getJobDetails(jobId: event.jobId);
      emit(JobDetailsLoaded(job: job));
    } catch (e) {
      emit(JobError(message: e.toString()));
    }
  }
}