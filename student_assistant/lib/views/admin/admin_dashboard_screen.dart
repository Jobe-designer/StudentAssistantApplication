import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widgets/app_drawer.dart';
import '/models/application.dart';
import '/viewmodels/application_viewmodel.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/views/edit_profile_screen.dart';

class AdminDashboardScreen
    extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen>
      createState() =>
          _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<
        AdminDashboardScreen> {
  ApplicationStatus?
      _filterStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        context
            .read<
                ApplicationViewModel>()
            .fetchAllApplications();
      },
    );
  }

  Future<void> _refresh() async {
    await context
        .read<
            ApplicationViewModel>()
        .fetchAllApplications(
          filterStatus:
              _filterStatus,
        );
  }

  Future<void> _setStatus(
    Application app,
    ApplicationStatus status,
  ) async {
    try {
      await context
          .read<
              ApplicationViewModel>()
          .updateApplicationStatus(
            app.id,
            status,
            currentFilter:
                _filterStatus,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Application ${status.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
        ),
      );
    }
  }

  Future<void> _openDocument(
    String? path,
  ) async {
    if (path == null ||
        path.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No document attached.',
          ),
        ),
      );

      return;
    }

    try {
      final signedUrl =
          await Supabase
              .instance.client.storage
              .from('documents')
              .createSignedUrl(
                path,
                60 * 10,
              );

      final uri =
          Uri.parse(signedUrl);

      if (!await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication,
      )) {
        if (!mounted) return;

        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open document.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

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

  Future<void>
      _deleteApplication(
    Application app,
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
          'Remove Application',
        ),
        content: Text(
          'Remove ${app.applicantName ?? 'this applicant'}\'s application?',
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
                const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await context
          .read<
              ApplicationViewModel>()
          .deleteApplication(
            app.id,
            adminMode: true,
            currentFilter:
                _filterStatus,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Application removed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
        ),
      );
    }
  }

  Color _getStatusColor(
    ApplicationStatus status,
  ) {
    switch (status) {
      case ApplicationStatus
            .approved:
        return Colors.green;

      case ApplicationStatus
            .rejected:
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Text(
            value,

            style: TextStyle(
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(
              height: 8),

          Text(
            title,

            style: const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentButton({
    required String title,
    required String? path,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,

      child: OutlinedButton.icon(
        onPressed: () =>
            _openDocument(path),

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              Colors.indigo,

          side: BorderSide(
            color:
                Colors.indigo.shade200,
          ),

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
  Widget build(
    BuildContext context,
  ) {
    final appVM =
        context.watch<
            ApplicationViewModel>();

    final authVM =
        context.read<AuthViewModel>();
        final admin =
    authVM.profile;

    final pendingCount = appVM
        .applications
        .where(
          (a) =>
              a.status ==
              ApplicationStatus
                  .pending,
        )
        .length;

    final approvedCount = appVM
        .applications
        .where(
          (a) =>
              a.status ==
              ApplicationStatus
                  .approved,
        )
        .length;

    final rejectedCount = appVM
        .applications
        .where(
          (a) =>
              a.status ==
              ApplicationStatus
                  .rejected,
        )
        .length;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
       drawer: AppDrawer(
  isAdmin: true,
  onProfile: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const EditProfileScreen(),
    ),
  );

  if (mounted) {
    await _refresh();
  }
},

  onAllApplications: () async {
    setState(() {
      _filterStatus = null;
    });

    await context
        .read<ApplicationViewModel>()
        .fetchAllApplications();
  },

  onPendingApplications: () async {
    setState(() {
      _filterStatus =
          ApplicationStatus.pending;
    });

    await context
        .read<ApplicationViewModel>()
        .fetchAllApplications(
          filterStatus:
              ApplicationStatus.pending,
        );
  },

  onApprovedApplications: () async {
    setState(() {
      _filterStatus =
          ApplicationStatus.approved;
    });

    await context
        .read<ApplicationViewModel>()
        .fetchAllApplications(
          filterStatus:
              ApplicationStatus.approved,
        );
  },

  onRejectedApplications: () async {
    setState(() {
      _filterStatus =
          ApplicationStatus.rejected;
    });

    await context
        .read<ApplicationViewModel>()
        .fetchAllApplications(
          filterStatus:
              ApplicationStatus.rejected,
        );
  },
),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        title: const Text(
          'Admin Dashboard',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        leading: Builder(
  builder: (context) => IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      Scaffold.of(context).openDrawer();
    },
  ),
),
      ),
      body: appVM.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,

              child: ListView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [
                   // ADMIN PROFILE CARD
                  Container(
                    padding:
                        const EdgeInsets
                            .all(20),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius:
                              10,
                          offset:
                              Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .indigo
                                .shade50,

                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons
                                .admin_panel_settings,

                            color:
                                Colors.indigo,

                            size: 34,
                          ),
                        ),

                        const SizedBox(
                            width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                admin?.fullName ??
                                    'Administrator',

                                style:
                                    const TextStyle(
                                  fontSize:
                                      22,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      6),

                              Text(
                                admin?.email ??
                                    'No email available',

                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade700,
                                  fontSize:
                                      15,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      10),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      12,
                                  vertical:
                                      6,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .indigo
                                      .shade50,

                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),

                                child:
                                    const Text(
                                  'ADMINISTRATOR',

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.indigo,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 24),
                  // HEADER
                  Container(
                    padding:
                        const EdgeInsets
                            .all(24),

                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Colors.indigo,
                          Colors.blue,
                        ],
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Text(
                          'Admin Dashboard',

                          style:
                              TextStyle(
                            fontSize: 30,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                            height:
                                10),

                        Text(
                          '${appVM.applications.length} application(s) available',

                          style:
                              const TextStyle(
                            color: Colors
                                .white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  // STATISTICS
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildStatCard(
                          'Pending',
                          pendingCount
                              .toString(),
                          Colors.orange,
                        ),
                      ),

                      const SizedBox(
                          width: 12),

                      Expanded(
                        child:
                            _buildStatCard(
                          'Approved',
                          approvedCount
                              .toString(),
                          Colors.green,
                        ),
                      ),

                      const SizedBox(
                          width: 12),

                      Expanded(
                        child:
                            _buildStatCard(
                          'Rejected',
                          rejectedCount
                              .toString(),
                          Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 24),

                  // FILTER
                  Container(
                    padding:
                        const EdgeInsets
                            .all(18),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius:
                              8,
                          offset:
                              Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt,
                          color:
                              Colors.indigo,
                        ),

                        const SizedBox(
                            width:
                                10),

                        const Text(
                          'Filter',

                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const Spacer(),

                        DropdownButton<
                            ApplicationStatus?>(
                          value:
                              _filterStatus,

                          items: const [
                            DropdownMenuItem<
                                ApplicationStatus?>(
                              value:
                                  null,
                              child:
                                  Text(
                                'All',
                              ),
                            ),

                            DropdownMenuItem(
                              value:
                                  ApplicationStatus.pending,
                              child:
                                  Text(
                                'Pending',
                              ),
                            ),

                            DropdownMenuItem(
                              value:
                                  ApplicationStatus.approved,
                              child:
                                  Text(
                                'Approved',
                              ),
                            ),

                            DropdownMenuItem(
                              value:
                                  ApplicationStatus.rejected,
                              child:
                                  Text(
                                'Rejected',
                              ),
                            ),
                          ],

                          onChanged:
                              (value) async {
                            setState(() {
                              _filterStatus =
                                  value;
                            });

                            await context
                                .read<
                                    ApplicationViewModel>()
                                .fetchAllApplications(
                                  filterStatus:
                                      value,
                                );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  // EMPTY STATE
                  if (appVM
                      .applications
                      .isEmpty)
                    Column(
                      children: const [
                        SizedBox(
                            height:
                                100),

                        Icon(
                          Icons
                              .inbox_outlined,
                          size: 90,
                          color:
                              Colors.grey,
                        ),

                        SizedBox(
                            height:
                                18),

                        Text(
                          'No applications found',

                          style:
                              TextStyle(
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    )

                  // APPLICATIONS
                  else
                    ...appVM
                        .applications
                        .map(
                      (app) {
                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom:
                                20,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              24,
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Colors.black12,
                                blurRadius:
                                    12,
                                offset:
                                    Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                          ),

                          child:
                              ExpansionTile(
                            tilePadding:
                                const EdgeInsets.all(
                              20,
                            ),

                            childrenPadding:
                                const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              20,
                            ),

                            leading:
                                Container(
                              padding:
                                  const EdgeInsets.all(
                                14,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .indigo
                                    .shade50,

                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .assignment_ind_outlined,

                                color:
                                    Colors.indigo,
                              ),
                            ),

                            title:
                                Text(
                              app.applicantName ??
                                  'Unknown Applicant',

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    18,
                              ),
                            ),

                            subtitle:
                                Padding(
                              padding:
                                  const EdgeInsets.only(
                                top:
                                    8,
                              ),

                              child:
                                  Text(
                                'Student No: ${app.applicantStudentNumber ?? 'Unknown'}',
                              ),
                            ),

                            trailing:
                                Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    14,
                                vertical:
                                    8,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    _getStatusColor(app.status).withOpacity(
                                  0.15,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),

                              child:
                                  Text(
                                app.status.name
                                    .toUpperCase(),

                                style:
                                    TextStyle(
                                  color:
                                      _getStatusColor(app.status),

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            children: [
                              Align(
                                alignment:
                                    Alignment.centerLeft,

                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'Year of Study: ${app.yearOfStudy}',
                                    ),

                                    const SizedBox(
                                        height:
                                            8),

                                    Text(
                                      'Eligibility Confirmed: ${app.eligibilityConfirmed ? 'Yes' : 'No'}',
                                    ),

                                    const SizedBox(
                                        height:
                                            18),

                                    const Text(
                                      'Modules',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            16,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            10),

                                    ...app.modules
                                        .map(
                                      (
                                        module,
                                      ) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(
                                            bottom:
                                                10,
                                          ),

                                          padding:
                                              const EdgeInsets.all(
                                            14,
                                          ),

                                          decoration:
                                              BoxDecoration(
                                            color: Colors
                                                .grey
                                                .shade50,

                                            borderRadius:
                                                BorderRadius.circular(
                                              16,
                                            ),
                                          ),

                                          child:
                                              Row(
                                            children: [
                                              const Icon(
                                                Icons.menu_book_outlined,

                                                color:
                                                    Colors.indigo,
                                              ),

                                              const SizedBox(
                                                  width:
                                                      12),

                                              Expanded(
                                                child:
                                                    Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,

                                                  children: [
                                                    Text(
                                                      module.moduleName,

                                                      style:
                                                          const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                        height:
                                                            4),

                                                    Text(
                                                      module.academicLevel,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(
                                        height:
                                            20),

                                    // DOCUMENTS
                                    const Text(
                                      'Documents',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            16,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            14),

                                    _documentButton(
                                      title:
                                          'Open ID Copy',

                                      path:
                                          app.idDocumentUrl,

                                      icon: Icons
                                          .badge_outlined,
                                    ),

                                    const SizedBox(
                                        height:
                                            12),

                                    _documentButton(
                                      title:
                                          'Open Matric Results',

                                      path:
                                          app.matricDocumentUrl,

                                      icon: Icons
                                          .school_outlined,
                                    ),

                                    const SizedBox(
                                        height:
                                            12),

                                    _documentButton(
                                      title:
                                          'Open Academic Record',

                                      path:
                                          app.academicRecordUrl,

                                      icon: Icons
                                          .menu_book_outlined,
                                    ),

                                    const SizedBox(
                                        height:
                                            24),

                                    // ACTIONS
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              ElevatedButton.icon(
                                            onPressed:
                                                () => _setStatus(
                                              app,
                                              ApplicationStatus.approved,
                                            ),

                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green,

                                              foregroundColor:
                                                  Colors.white,

                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical:
                                                    16,
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
                                                  .check_circle,
                                            ),

                                            label:
                                                const Text(
                                              'Approve',
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                12),

                                        Expanded(
                                          child:
                                              ElevatedButton.icon(
                                            onPressed:
                                                () => _setStatus(
                                              app,
                                              ApplicationStatus.rejected,
                                            ),

                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade50,

                                              foregroundColor:
                                                  Colors.red,

                                              elevation:
                                                  0,

                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical:
                                                    16,
                                              ),

                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  16,
                                                ),

                                                side:
                                                    BorderSide(
                                                  color:
                                                      Colors.red.shade200,
                                                ),
                                              ),
                                            ),

                                            icon:
                                                const Icon(
                                              Icons
                                                  .close,
                                            ),

                                            label:
                                                const Text(
                                              'Reject',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              OutlinedButton.icon(
                                            onPressed:
                                                () => _setStatus(
                                              app,
                                              ApplicationStatus.pending,
                                            ),

                                            style:
                                                OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.orange,

                                              side:
                                                  BorderSide(
                                                color: Colors
                                                    .orange
                                                    .shade200,
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
                                                  .pending_actions,
                                            ),

                                            label:
                                                const Text(
                                              'Set Pending',
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                12),

                                        Expanded(
                                          child:
                                              OutlinedButton.icon(
                                            onPressed:
                                                () => _deleteApplication(
                                              app,
                                            ),

                                            style:
                                                OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.grey.shade700,

                                              side:
                                                  BorderSide(
                                                color: Colors
                                                    .grey
                                                    .shade300,
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
                                              'Remove',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}