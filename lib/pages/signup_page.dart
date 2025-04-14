// lib/pages/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/bloc/auth_bloc.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/widgets/input_field.dart';
import 'package:gig_marketplace/widgets/form_container.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _businessRegistrationController = TextEditingController();
  
  UserRole _selectedRole = UserRole.employee;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _resumeFile;
  String? _resumeFileName;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _businessRegistrationController.dispose();
    super.dispose();
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

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      // Only validate employee specific fields if employee role is selected
      bool isEmployeeFieldsValid = _selectedRole != UserRole.employee || _resumeFile != null;
      
      // Only validate employer specific fields if employer role is selected
      bool isEmployerFieldsValid = _selectedRole != UserRole.employer || 
          (_companyNameController.text.isNotEmpty && _businessRegistrationController.text.isNotEmpty);
      
      if (!isEmployeeFieldsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your resume'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!isEmployerFieldsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide company details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(SignUpEvent(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        companyName: _selectedRole == UserRole.employer ? _companyNameController.text.trim() : null,
        businessRegistrationNumber: _selectedRole == UserRole.employer ? _businessRegistrationController.text.trim() : null,
        resumeUrl: _selectedRole == UserRole.employee ? _resumeFile?.path : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Navigate to home or job listing page
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator(message: 'Creating your account...');
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Basic Information
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
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Basic email validation
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      InputField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      InputField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        prefixIcon: Icons.lock,
                        isRequired: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      InputField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        prefixIcon: Icons.lock_clock,
                        isRequired: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Role Selection
                  FormContainer(
                    title: 'I want to join as',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<UserRole>(
                              title: const Text('Employee'),
                              value: UserRole.employee,
                              groupValue: _selectedRole,
                              onChanged: (UserRole? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<UserRole>(
                              title: const Text('Employer'),
                              value: UserRole.employer,
                              groupValue: _selectedRole,
                              onChanged: (UserRole? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Role-specific fields
                  if (_selectedRole == UserRole.employee) ...[
                    FormContainer(
                      title: 'Resume',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _resumeFileName ?? 'No file selected',
                                style: TextStyle(
                                  color: _resumeFileName == null ? Colors.grey : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _pickResume,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Resume'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  
                  if (_selectedRole == UserRole.employer) ...[
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
                  
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _signUp,
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          // Navigate back to sign in page
                          Navigator.of(context).pop();
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}