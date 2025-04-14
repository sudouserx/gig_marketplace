// lib/pages/profile_page.dart (completed)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/bloc/auth_bloc.dart';
import 'package:gig_marketplace/bloc/profile_bloc.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/widgets/input_field.dart';
import 'package:gig_marketplace/widgets/form_container.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _companyNameController;
  late TextEditingController _businessRegistrationController;
  
  File? _profilePictureFile;
  File? _resumeFile;
  String? _resumeFileName;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _companyNameController = TextEditingController();
    _businessRegistrationController = TextEditingController();
    
    // Get the current user
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Load profile data
      context.read<ProfileBloc>().add(LoadProfileEvent(userId: authState.user.id));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _companyNameController.dispose();
    _businessRegistrationController.dispose();
    super.dispose();
  }

  void _populateFormFields(User user) {
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phoneNumber;
    _bioController.text = user.bio ?? '';
    
    if (user.role == UserRole.employer) {
      _companyNameController.text = user.companyName ?? '';
      _businessRegistrationController.text = user.businessRegistrationNumber ?? '';
    }
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profilePictureFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeFileName = result.files.single.name;
      });
    }
  }

  void _updateProfile(User user) {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(UpdateProfileEvent(
        userId: user.id,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        profilePicture: _profilePictureFile,
        resume: _resumeFile,
        companyName: user.role == UserRole.employer ? _companyNameController.text.trim() : null,
        businessRegistrationNumber: user.role == UserRole.employer ? _businessRegistrationController.text.trim() : null,
      ));
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _signOut() {
    context.read<AuthBloc>().add(SignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'Sign Out',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // Navigate to sign in page when signed out
            Navigator.of(context).pushReplacementNamed('/signin');
          }
        },
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProfileUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const LoadingIndicator(message: 'Loading profile...');
            }
            
            if (state is ProfileError) {
              return ErrorDisplay(
                errorMessage: state.message,
                onRetry: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.read<ProfileBloc>().add(LoadProfileEvent(userId: authState.user.id));
                  }
                },
              );
            }
            
            User? user;
            if (state is ProfileLoaded) {
              user = state.user;
              if (!_isEditing) {
                _populateFormFields(user);
              }
            } else if (state is ProfileUpdated) {
              user = state.user;
              if (!_isEditing) {
                _populateFormFields(user);
              }
            }
            
            if (user == null) {
              return const Center(child: Text('No profile data available'));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profilePictureFile != null 
                              ? FileImage(_profilePictureFile!) 
                              : (user.profilePicture != null 
                                  ? NetworkImage(user.profilePicture!) as ImageProvider 
                                  : null),
                          child: user.profilePicture == null && _profilePictureFile == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        if (_isEditing)
                          GestureDetector(
                            onTap: _pickProfilePicture,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.role == UserRole.employee ? 'Employee' : 'Employer',
                      style: TextStyle(
                        color: user.role == UserRole.employee ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (!_isEditing) ...[
                      // Display mode
                      FormContainer(
                        title: 'Contact Information',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Phone Number'),
                            subtitle: Text(user.phoneNumber),
                          ),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.description),
                              title: const Text('Bio'),
                              subtitle: Text(user.bio!),
                            ),
                          ],
                        ],
                      ),
                      
                      if (user.role == UserRole.employer && 
                          (user.companyName != null || user.businessRegistrationNumber != null)) ...[
                        const SizedBox(height: 16),
                        FormContainer(
                          title: 'Company Information',
                          children: [
                            if (user.companyName != null) ...[
                              ListTile(
                                leading: const Icon(Icons.business),
                                title: const Text('Company Name'),
                                subtitle: Text(user.companyName!),
                              ),
                            ],
                            if (user.businessRegistrationNumber != null) ...[
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.numbers),
                                title: const Text('Business Registration'),
                                subtitle: Text(user.businessRegistrationNumber!),
                              ),
                            ],
                          ],
                        ),
                      ],
                      
                      if (user.role == UserRole.employee && user.resumeUrl != null) ...[
                        const SizedBox(height: 16),
                        FormContainer(
                          title: 'Resume',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.file_present),
                              title: const Text('View Resume'),
                              subtitle: const Text('Click to download or view your resume'),
                              trailing: const Icon(Icons.download),
                              onTap: () {
                                // Implement resume download/view logic
                              },
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Edit Profile',
                        icon: Icons.edit,
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                    ] else ...[
                      // Edit mode
                      FormContainer(
                        title: 'Basic Information',
                        children: [
                          InputField(
                            label: 'Full Name',
                            controller: _fullNameController,
                            prefixIcon: Icons.person,
                            isRequired: true,
                          ),
                          InputField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone,
                            isRequired: true,
                          ),
                          InputField(
                            label: 'Bio',
                            controller: _bioController,
                            maxLines: 3,
                            prefixIcon: Icons.description,
                          ),
                        ],
                      ),
                      
                      if (user.role == UserRole.employer) ...[
                        const SizedBox(height: 16),
                        FormContainer(
                          title: 'Company Information',
                          children: [
                            InputField(
                              label: 'Company Name',
                              controller: _companyNameController,
                              prefixIcon: Icons.business,
                              isRequired: true,
                            ),
                            InputField(
                              label: 'Business Registration Number',
                              controller: _businessRegistrationController,
                              prefixIcon: Icons.numbers,
                              isRequired: true,
                            ),
                          ],
                        ),
                      ],
                      
                      if (user.role == UserRole.employee) ...[
                        const SizedBox(height: 16),
                        FormContainer(
                          title: 'Resume',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _resumeFileName ?? (user.resumeUrl != null ? 'Current resume file' : 'No resume uploaded'),
                                    style: TextStyle(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _pickResume,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Resume'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Supported formats: PDF, DOC, DOCX',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Cancel',
                              icon: Icons.cancel,
                              backgroundColor: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  // Reset files
                                  _profilePictureFile = null;
                                  _resumeFile = null;
                                  _resumeFileName = null;
                                  // Restore original values
                                  _populateFormFields(user!);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: 'Save Changes',
                              icon: Icons.save,
                              onPressed: () => _updateProfile(user!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}