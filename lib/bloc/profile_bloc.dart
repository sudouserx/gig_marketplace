// lib/bloc/profile_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/repositories/user_repository.dart';

// Events
abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {
  final String userId;

  LoadProfileEvent({required this.userId});
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final File? profilePicture;
  final File? resume;
  final String? companyName;
  final String? businessRegistrationNumber;

  UpdateProfileEvent({
    required this.userId,
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.profilePicture,
    this.resume,
    this.companyName,
    this.businessRegistrationNumber,
  });
}

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;

  ProfileLoaded({required this.user});
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError({required this.message});
}

class ProfileUpdated extends ProfileState {
  final User user;

  ProfileUpdated({required this.user});
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository userRepository;

  ProfileBloc({required this.userRepository}) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await userRepository.getUserProfile(event.userId);
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await userRepository.updateUserProfile(
        userId: event.userId,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        bio: event.bio,
        profilePicture: event.profilePicture,
        resume: event.resume,
        companyName: event.companyName,
        businessRegistrationNumber: event.businessRegistrationNumber,
      );
      emit(ProfileUpdated(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}