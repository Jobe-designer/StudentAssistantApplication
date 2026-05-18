// lib/views/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant/viewmodel/application_viewmodel.dart';
import 'package:student_assistant/viewmodel/auth_viewmodel.dart';
import 'login_screen.dart';
import '../student/student_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final appVM = context.watch<ApplicationViewModel>();
    
    if (authVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (!authVM.isLoggedIn) {
      return const LoginScreen();
    }
    
    // Load data after auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authVM.currentUserId != null) {
        if (authVM.isAdmin) {
          appVM.fetchAllApplications();
        } else {
          appVM.fetchMyApplications(authVM.currentUserId!);
        }
      }
    });
    
    if (authVM.isAdmin) {
      return const AdminDashboardScreen();
    }
    return const StudentHomeScreen();
  }
}