
import 'package:flutter/material.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/student/application_form_screen.dart';
import '../views/login/login_screen.dart';
import '../views/student/student_home_screen.dart';

class RouteManager {
  static const String login = '/login';
  static const String studentHome = '/student/home';
  static const String adminDashboard = '/admin-dashboard';
  static const String applicationForm = '/application-form';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case applicationForm:
        return MaterialPageRoute(builder: (_) => const ApplicationFormScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
