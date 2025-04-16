// lib/main.dart
import 'dart:js';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/bloc/auth_bloc.dart';
import 'package:gig_marketplace/bloc/job_bloc.dart';
import 'package:gig_marketplace/bloc/profile_bloc.dart';
import 'package:gig_marketplace/bloc/application_bloc.dart';

import 'package:gig_marketplace/pages/created_jobs_page.dart';
import 'package:gig_marketplace/pages/profile_page.dart';
import 'package:gig_marketplace/pages/signin_page.dart';
import 'package:gig_marketplace/pages/signup_page.dart';
import 'package:gig_marketplace/pages/job_listing_page.dart';
import 'package:gig_marketplace/pages/job_detail_page.dart';

import 'package:gig_marketplace/repositories/auth_repository.dart';
// import 'package:gig_marketplace/repositories/mock_auth_repository.dart';

import 'package:gig_marketplace/repositories/job_repository.dart';
import 'package:gig_marketplace/repositories/user_repository.dart';
import 'package:gig_marketplace/repositories/application_repository.dart';
import 'package:gig_marketplace/repositories/messaging_repository.dart';
import 'package:gig_marketplace/services/api_service.dart';
// import 'package:gig_marketplace/services/mock_auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create shared instances of services and repositories
    final apiService = ApiService();
    // final mockAuthService = MockAuthService();
    final authRepository = AuthRepository(apiService: apiService);
    final userRepository = UserRepository(apiService: apiService);
    final jobRepository = JobRepository(apiService: apiService);
    final applicationRepository = ApplicationRepository(apiService: apiService);
    final messagingRepository = MessagingRepository(apiService: apiService);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository: authRepository)
            ..add(CheckAuthStatusEvent()), // Add check auth status event
        ),
        BlocProvider<JobBloc>(
          create: (context) => JobBloc(jobRepository: jobRepository),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(userRepository: userRepository),
        ),
        BlocProvider<ApplicationBloc>(
          create: (context) =>
              ApplicationBloc(applicationRepository: applicationRepository),
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ApiService>(
            create: (context) => apiService,
          ),
          RepositoryProvider<AuthRepository>(
            create: (context) => authRepository,
          ),
          RepositoryProvider<UserRepository>(
            create: (context) => userRepository,
          ),
          RepositoryProvider<JobRepository>(
            create: (context) => jobRepository,
          ),
          RepositoryProvider<ApplicationRepository>(
            create: (context) => applicationRepository,
          ),
          RepositoryProvider<MessagingRepository>(
            create: (context) => messagingRepository,
          ),
        ],
        child: MaterialApp(
          title: 'Gig Marketplace',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // Show splash screen while checking auth status
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If authenticated, navigate directly to CreatedJobsPage
              if (state is AuthAuthenticated) {
                // return const HomePage();

                // return const CreatedJobsPage();
                // return const JobListingPage(isEmployer: true);
                return const ProfilePage();
              }

              // Default to sign in page
              return const SignInPage();
            },
          ),
          routes: {
            '/signin': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
            '/home': (context) => const ProfilePage(),
            '/profile': (context) => const ProfilePage(),
            '/job-details': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return DetailJobPage(
                jobId: args['jobId'],
                isFromEmployerDashboard:
                    args['isFromEmployerDashboard'] ?? false,
              );
            },

            // Add more routes as needed
          },
        ),
      ),
    );
  }
}
