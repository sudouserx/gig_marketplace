import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/repositories/auth_repository.dart';
import 'package:gig_marketplace/widgets/BottomNavBar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Connect App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF2A3990)),
          titleTextStyle: TextStyle(
            color: Color(0xFF2A3990),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  bool _isLoading = true;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authRepository = RepositoryProvider.of<AuthRepository>(context);
      final user = await authRepository.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user: ${e.toString()}')),
      );
    }
  }

  void _handleNavTap(int index) {
    if (index != _currentNavIndex) {
      setState(() {
        _currentNavIndex = index;
      });
      
      switch (index) {
        case 1:
          Navigator.pushNamed(context, '/jobs');
          break;
        case 2:
          Navigator.pushNamed(context, '/messages');
          break;
        case 3:
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(
              child: Text('Please login to continue'),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildWelcomeSection(),
                    const SizedBox(height: 30),
                    _buildGridMenuSection(context),
                    const SizedBox(height: 30),
                    _buildRecentActivitySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
        backgroundColor: const Color(0xFF2A3990),
        child: const Icon(Icons.chat_bubble_outline),
        tooltip: 'AI Chatbot',
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _handleNavTap,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A3990), Color(0xFF5563D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back, ${_currentUser?.fullName ?? "User"}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currentUser?.role == UserRole.employer 
                ? 'Find talented professionals for your opportunities' 
                : 'Find your perfect job opportunity today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Search jobs, companies...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenuSection(BuildContext context) {
    final bool isEmployer = _currentUser?.role == UserRole.employer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: isEmployer
              ? [
                  // For Employer
                  _buildGridItem(
                    context,
                    'Create Job',
                    Icons.add_box_outlined,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF4CAF50),
                    '/create-job',
                  ),
                  _buildGridItem(
                    context,
                    'Created Jobs',
                    Icons.post_add_outlined,
                    const Color(0xFFFFF8E1),
                    const Color(0xFFFFC107),
                    '/created-jobs',
                  ),
                  _buildGridItem(
                    context,
                    'Jobs Listing',
                    Icons.work_outlined,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF2196F3),
                    '/jobs',
                  ),
                  _buildGridItem(
                    context,
                    'Messages',
                    Icons.message_outlined,
                    const Color(0xFFE1F5FE),
                    const Color(0xFF03A9F4),
                    '/messages',
                  ),
                ]
              : [
                  // For Employee
                  _buildGridItem(
                    context,
                    'Applied Jobs',
                    Icons.description_outlined,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF4CAF50),
                    '/applied-jobs',
                  ),
                  _buildGridItem(
                    context,
                    'Jobs Listing',
                    Icons.work_outlined,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF2196F3),
                    '/jobs',
                  ),
                  _buildGridItem(
                    context,
                    'Messages',
                    Icons.message_outlined,
                    const Color(0xFFE1F5FE),
                    const Color(0xFF03A9F4),
                    '/messages',
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    String route,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final bool isEmployer = _currentUser?.role == UserRole.employer;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 15),
        if (isEmployer) ...[
          _buildActivityItem(
            'Senior Developer',
            'Posted 3 days ago',
            '4 applications received',
            Colors.blue,
          ),
          _buildActivityItem(
            'Product Manager',
            'Posted 5 days ago',
            'Interview scheduled with Alex',
            Colors.green,
          ),
          _buildActivityItem(
            'UI/UX Designer',
            'Posted 1 week ago',
            'New candidate message',
            Colors.orange,
          ),
        ] else ...[
          _buildActivityItem(
            'UI/UX Designer',
            'Google Inc.',
            'Applied 2 days ago',
            Colors.blue,
          ),
          _buildActivityItem(
            'Flutter Developer',
            'Microsoft',
            'Interview scheduled on May 22',
            Colors.green,
          ),
          _buildActivityItem(
            'Product Manager',
            'Apple Inc.',
            'New message received',
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String company,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                title.substring(0, 1),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  company,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}