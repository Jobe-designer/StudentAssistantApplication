// lib/views/auth/login_screen.dart - COMPLETE WORKING VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../utils/validate.dart';
import '../../viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _showAdminCode = false;
  bool _isAdminLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = context.read<AuthViewModel>();
    
    bool success;
    
    if (_isAdminLogin) {
      success = await authVM.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        adminSecretCode: _adminCodeController.text.trim(),
      );
    } else {
      success = await authVM.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'Login failed'), 
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, size: 45, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Student Assistant',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text(
                      'Application Portal',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    
                    // Login Type Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          _buildToggleButton('Student', !_isAdminLogin),
                          const SizedBox(width: 8),
                          _buildToggleButton('Admin', _isAdminLogin),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                            validator: AppValidators.validatePassword,
                          ),
                          
                          // Admin Secret Code Field
                          if (_showAdminCode) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _adminCodeController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Admin Secret Code',
                                prefixIcon: Icon(Icons.admin_panel_settings),
                              ),
                              validator: (value) {
                                if (_isAdminLogin && (value == null || value.isEmpty)) {
                                  return 'Admin secret code is required';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Login Button
                          Consumer<AuthViewModel>(
                            builder: (context, authVM, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authVM.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: authVM.isLoading
                                      ? const SizedBox(
                                          height: 20, 
                                          width: 20, 
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isAdminLogin ? 'ADMIN LOGIN' : 'STUDENT LOGIN',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Demo Credentials
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Demo Credentials',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, size: 14, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              const Text('student@cut.ac.za', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 16),
                              Icon(Icons.lock, size: 14, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              const Text('password123', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Admin: admin@cut.ac.za | Secret Code: ADMIN2026',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAdminLogin = !_isAdminLogin;
            _showAdminCode = _isAdminLogin;
            if (!_isAdminLogin) {
              _adminCodeController.clear();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}