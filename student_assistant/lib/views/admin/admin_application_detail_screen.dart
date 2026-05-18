// lib/views/admin/admin_application_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant/models/application_models.dart';
import 'package:student_assistant/viewmodel/application_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const AdminApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<AdminApplicationDetailScreen> createState() => _AdminApplicationDetailScreenState();
}

class _AdminApplicationDetailScreenState extends State<AdminApplicationDetailScreen> {
  late ApplicationModel _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  void _loadApplication() {
    final appVM = context.read<ApplicationViewModel>();
    _application = appVM.applications.firstWhere((a) => a.id == widget.applicationId);
    setState(() => _isLoading = false);
  }

  Future<void> _openFile(String? url, String fileType) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file uploaded'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    String fullUrl = url;
    if (!url.startsWith('http')) {
      final supabase = Supabase.instance.client;
      fullUrl = supabase.storage
          .from('application_documents')
          .getPublicUrl(url);
    }
    
    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $fullUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveApplication() async {
    final appVM = context.read<ApplicationViewModel>();
    final success = await appVM.approveApplication(_application.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application approved!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appVM.errorMessage ?? 'Approval failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectApplication() async {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text;
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason'), backgroundColor: Colors.red),
                );
                return;
              }
              final success = await context.read<ApplicationViewModel>().rejectApplication(_application.id, reason);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application rejected'), backgroundColor: Colors.orange),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rejection failed'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApplication() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<ApplicationViewModel>().deleteApplication(_application.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application deleted'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_application.status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_application.status == 'pending')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteApplication,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _application.status.toUpperCase(),
                  style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Student Information
            _buildInfoCard('Student Information', [
              _buildInfoRow('Student Number', _application.studentNumber),
              _buildInfoRow('Full Name', _application.fullName),
              _buildInfoRow('Email', _application.email),
              _buildInfoRow('Year of Study', _application.yearOfStudy.toString()),
            ]),
            const SizedBox(height: 16),
            
            // First Module
            _buildInfoCard('First Module', [
              _buildInfoRow('Level', _application.firstModuleLevel),
              _buildInfoRow('Module', _application.firstModuleName),
              _buildInfoRow('Reason', _application.firstModuleReason),
            ]),
            
            if (_application.hasSecondModule) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Second Module', [
                _buildInfoRow('Level', _application.secondModuleLevel ?? ''),
                _buildInfoRow('Module', _application.secondModuleName ?? ''),
                _buildInfoRow('Reason', _application.secondModuleReason ?? ''),
              ]),
            ],
            
            const SizedBox(height: 16),
            
            // Uploaded Documents Section
            _buildInfoCard('Supporting Documents', [
              _buildDocumentRow('CV', _application.cvUrl),
              _buildDocumentRow('Academic Record', _application.academicRecordUrl),
            ]),
            
            if (_application.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Rejection Reason', [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_application.rejectionReason!),
                ),
              ]),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons (only for pending applications)
            if (_application.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approveApplication,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('APPROVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _rejectApplication,
                      icon: const Icon(Icons.cancel),
                      label: const Text('REJECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String title, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 120, child: Text('Documents:', style: TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: InkWell(
              onTap: () => _openFile(url, title),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url != null && url.isNotEmpty ? title : 'No file uploaded',
                        style: TextStyle(
                          color: url != null && url.isNotEmpty ? Colors.blue : Colors.grey,
                          decoration: url != null && url.isNotEmpty ? TextDecoration.underline : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (url != null && url.isNotEmpty)
                      const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}