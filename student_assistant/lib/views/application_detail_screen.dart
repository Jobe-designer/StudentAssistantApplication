import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';
import '../viewmodels/application_viewmodel.dart';
import '/views/student/application_form_screen.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final Application application;

  const ApplicationDetailScreen({
    super.key,
    required this.application,
  });

  Future<void> _openDocument(
    BuildContext context,
    String? path,
  ) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No document attached.',
          ),
        ),
      );

      return;
    }

    try {
      final signedUrl = await Supabase
          .instance.client.storage
          .from('documents')
          .createSignedUrl(path, 60 * 10);

      final uri = Uri.parse(signedUrl);

      if (!await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      )) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open document.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open document.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) =>
          AlertDialog(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        title: const Text(
          'Delete Application',
        ),

        content: const Text(
          'Are you sure you want to delete this pending application?',
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),

            child:
                const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),

            child:
                const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !context.mounted) {
      return;
    }

    final navigator =
        Navigator.of(context);

    final messenger =
        ScaffoldMessenger.of(context);

    try {
      await context
          .read<
              ApplicationViewModel>()
          .deleteApplication(
        application.id,
        pendingOnly: true,
      );

      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Application deleted.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
        ),
      );
    }
  }

  String _statusName() {
    return application.status.name;
  }

  Color _statusColor() {
    switch (_statusName()
        .toLowerCase()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon() {
    switch (_statusName()
        .toLowerCase()) {
      case 'approved':
        return Icons
            .check_circle_outline;

      case 'rejected':
        return Icons.cancel_outlined;

      default:
        return Icons.access_time;
    }
  }

  Widget _documentButton({
    required BuildContext context,
    required String title,
    required String? path,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,

      child: ElevatedButton.icon(
        onPressed: () =>
            _openDocument(
          context,
          path,
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.indigo,

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),

        icon: Icon(icon),

        label: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        application.isPending;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        title: const Text(
          'Application Details',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // STATUS CARD
            Container(
              padding:
                  const EdgeInsets.all(
                24,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: const [
                  BoxShadow(
                    color:
                        Colors.black12,

                    blurRadius: 10,

                    offset:
                        Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .all(14),

                        decoration:
                            BoxDecoration(
                          color:
                              _statusColor()
                                  .withOpacity(
                            0.15,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),

                        child: Icon(
                          _statusIcon(),

                          color:
                              _statusColor(),

                          size: 32,
                        ),
                      ),

                      const SizedBox(
                          width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Text(
                              'Application Status',

                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,

                                fontSize:
                                    14,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    4),

                            Text(
                              _statusName()
                                  .toUpperCase(),

                              style:
                                  TextStyle(
                                fontSize:
                                    28,

                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    _statusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 24),

                  const Divider(),

                  const SizedBox(
                      height: 18),

                  _InfoRow(
                    label:
                        'Current year of study',

                    value: application
                            .yearOfStudy
                            .isEmpty
                        ? 'Unknown'
                        : application
                            .yearOfStudy,
                  ),

                  _InfoRow(
                    label:
                        'Eligibility confirmed',

                    value: application
                            .eligibilityConfirmed
                        ? 'Yes'
                        : 'No',
                  ),

                  _InfoRow(
                    label: 'Submitted',

                    value: application
                        .createdAt
                        .toLocal()
                        .toString(),
                  ),
                ],
              ),
            ),
// CV DOCUMENT
const SizedBox(height: 14),
        // MODULES TITLE
            const Text(
              'Modules Applied For',

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            // MODULES
            if (application
                .modules.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  'No modules found.',
                ),
              )
            else
              ...application.modules.map(
                (module) => Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 14,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color:
                            Colors.black12,

                        blurRadius: 10,

                        offset:
                            Offset(0, 4),
                      ),
                    ],
                  ),

                  child: ListTile(
                    contentPadding:
                        const EdgeInsets
                            .all(18),

                    leading: Container(
                      padding:
                          const EdgeInsets
                              .all(12),

                      decoration:
                          BoxDecoration(
                        color: Colors
                            .indigo
                            .shade50,

                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .menu_book_outlined,

                        color:
                            Colors.indigo,
                      ),
                    ),

                    title: Text(
                      module.moduleName
                              .isEmpty
                          ? 'Unknown Module'
                          : module
                              .moduleName,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 6,
                      ),

                      child: Text(
                        module
                                .academicLevel
                                .isEmpty
                            ? 'Unknown Level'
                            : module
                                .academicLevel,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // DOCUMENTS TITLE
            const Text(
              'Supporting Documents',

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            // ID COPY
            _documentButton(
              context: context,

              title: 'Open ID Copy',

              path:
                  application
                      .idDocumentUrl,

              icon:
                  Icons.badge_outlined,
            ),

            const SizedBox(height: 14),

            // MATRIC RESULTS
            _documentButton(
              context: context,

              title:
                  'Open Matric Results',

              path: application
                  .matricDocumentUrl,

              icon:
                  Icons.school_outlined,
            ),

            const SizedBox(height: 14),

            // ACADEMIC RECORD
            _documentButton(
              context: context,

              title:
                  'Open Academic Record',

              path: application
                  .academicRecordUrl,

              icon: Icons
                  .menu_book_outlined,
            ),
const SizedBox(height: 14),

_documentButton(
  context: context,

  title:
      'Open Curriculum Vitae (CV)',

  path: application.academicRecordUrl,

  icon:
      Icons.description_outlined,
),
            const SizedBox(height: 28),

            // EDIT + DELETE
            if (canManage)
              Row(
                children: [
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              ApplicationFormScreen(
                            application:
                                application,
                          ),
                        ),
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.indigo,

                        foregroundColor:
                            Colors.white,

                        padding:
                            const EdgeInsets.symmetric(
                          vertical:
                              15,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),

                      icon:
                          const Icon(
                        Icons.edit,
                      ),

                      label:
                          const Text(
                        'Edit',
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 14),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: () =>
                          _delete(
                        context,
                      ),

                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            Colors.red,

                        side:
                            const BorderSide(
                          color:
                              Colors.red,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          vertical:
                              15,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),

                      icon:
                          const Icon(
                        Icons
                            .delete_outline,
                      ),

                      label:
                          const Text(
                        'Delete',
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration: BoxDecoration(
                  color: Colors.orange
                      .withOpacity(
                    0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,

                      color:
                          Colors.orange,
                    ),

                    const SizedBox(
                        width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: const [
                          Text(
                            'This application can no longer be edited or deleted.',

                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                              height: 4),

                          Text(
                            'Only pending applications can be managed by students.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 180,

            child: Text(
              '$label:',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}