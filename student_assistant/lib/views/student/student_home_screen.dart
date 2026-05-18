// lib/views/student/student_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/application_models.dart';
import '../../viewmodel/application_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'application_form_screen.dart';
import 'application_detail_screen.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDataOnce());
  }

  Future<void> _loadDataOnce() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    final authVM = context.read<AuthViewModel>();
    if (authVM.currentUserId != null) {
      await context.read<ApplicationViewModel>().fetchMyApplications(authVM.currentUserId!);
    }
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    final authVM = context.read<AuthViewModel>();
    if (authVM.currentUserId != null) {
      await context.read<ApplicationViewModel>().fetchMyApplications(authVM.currentUserId!);
    }
    
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<ApplicationViewModel>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Student Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          'Welcome, ${context.read<AuthViewModel>().currentStudentName}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await context.read<AuthViewModel>().signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: appVM.applications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appVM.applications.length,
                itemBuilder: (context, index) => _buildApplicationCard(appVM.applications[index], appVM),
              ),
            ),
      floatingActionButton: appVM.canSubmitApplication
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const ApplicationFormScreen()),
                );
                if (result == true) await _refreshData();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Application'),
              backgroundColor: AppTheme.accent,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, size: 60, color: AppTheme.accent),
          ),
          const SizedBox(height: 24),
          const Text('No Applications Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the + button to submit your first application', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel app, ApplicationViewModel appVM) {
    Color statusColor;
    IconData statusIcon;
    switch (app.status) {
      case 'approved':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.warning;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: app.id))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.firstModuleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${app.firstModuleLevel} • ${app.createdAt.toString().substring(0, 10)}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(app.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              if (app.status == 'pending')
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Application')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationFormScreen(application: app)));
                      await _refreshData();
                    } else if (value == 'delete') {
                      await appVM.deleteApplication(app.id);
                      await _refreshData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Application deleted'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}