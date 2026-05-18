// lib/views/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/application_models.dart';
import '../../viewmodel/application_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'admin_application_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  bool _isRefreshing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDataOnce());
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDataOnce() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    try {
      await context.read<ApplicationViewModel>().fetchAllApplications();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) setState(() {
        _isRefreshing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    try {
      await context.read<ApplicationViewModel>().fetchAllApplications();
    } catch (e) {
      print('Error refreshing: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  List<ApplicationModel> _getFilteredApplications(ApplicationViewModel appVM) {
    var apps = appVM.applications;
    
    if (_statusFilter != 'all') apps = apps.where((a) => a.status == _statusFilter).toList();
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      apps = apps.where((a) => a.fullName.toLowerCase().contains(query) || a.studentNumber.contains(query)).toList();
    }
    return apps;
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<ApplicationViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Manage applications', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refreshData),
                  IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
                    await context.read<AuthViewModel>().signOut();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard('Total', appVM.applications.length, Colors.blue),
                      _buildStatCard('Pending', appVM.pendingCount, AppTheme.warning),
                      _buildStatCard('Approved', appVM.approvedCount, AppTheme.success),
                      _buildStatCard('Rejected', appVM.rejectedCount, AppTheme.error),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or student number...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.accent),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
                // Applications List
                Expanded(
                  child: _getFilteredApplications(appVM).isEmpty
                      ? Center(child: Text('No applications found', style: TextStyle(color: Colors.grey[400])))
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          color: AppTheme.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _getFilteredApplications(appVM).length,
                            itemBuilder: (context, index) => _buildApplicationCard(_getFilteredApplications(appVM)[index], appVM),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) => setState(() => _statusFilter = value),
      backgroundColor: AppTheme.surface,
      selectedColor: AppTheme.accent,
      labelStyle: TextStyle(color: _statusFilter == value ? Colors.white : Colors.grey),
    );
  }

  Widget _buildApplicationCard(ApplicationModel app, ApplicationViewModel appVM) {
    Color statusColor = app.status == 'approved' ? AppTheme.success : (app.status == 'rejected' ? AppTheme.error : AppTheme.warning);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminApplicationDetailScreen(applicationId: app.id))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(app.studentNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(app.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(app.firstModuleName, style: const TextStyle(fontSize: 14)),
              if (app.hasSecondModule) Text('+ ${app.secondModuleName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}