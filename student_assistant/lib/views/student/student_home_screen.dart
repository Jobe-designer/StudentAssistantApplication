
import 'package:flutter/material.dart';
import 'package:student_assistant/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant/viewmodels/application_viewmodel.dart';
import 'package:student_assistant/viewmodels/auth_viewmodel.dart';
import 'package:student_assistant/views/application_detail_screen.dart';
import 'package:student_assistant/views/student/application_form_screen.dart';
import 'package:student_assistant/views/edit_profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationViewModel>().fetchUserApplications();
    });
  }

  Future<void> _refresh() => context.read<ApplicationViewModel>().fetchUserApplications();

  Future<void> _openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplicationFormScreen()));
    if (mounted) await _refresh();
  }

  Future<void> _openDetails(application) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationDetailScreen(application: application)));
    if (mounted) await _refresh();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<ApplicationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
       drawer: AppDrawer(
  isAdmin: false,

  onNewApplication: _openForm,

  onMyApplications: () {},

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
),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: Builder(
  builder: (context) => IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      Scaffold.of(context).openDrawer();
    },
  ),
),
        title: const Text(
          'Student Portal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.indigo,
                    Colors.blue,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName ?? 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'User Number: ${profile?.userNumber ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'My Applications',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 14),

    if (appVM.applications.isEmpty)
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              appVM.isLoading
                  ? null
                  : _openForm,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.indigo,
            foregroundColor:
                Colors.white,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
          ),

          icon:
              const Icon(Icons.add),

          label: const Text(
            'Apply',
          ),
        ),
      ),
  ],
),

            const SizedBox(height: 16),

            if (appVM.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            else if (appVM.applications.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                    Icon(
                      Icons.assignment_outlined,
                      size: 60,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'No applications submitted yet.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _openForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Submit Application'),
                    ),
                  ],
                ),
              )

            else
              ...appVM.applications.map(
                (app) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),

                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.indigo,
                      ),
                    ),

                    title: Text(
                      'Year of Study: ${app.yearOfStudy}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${app.modules.length} module(s)',
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                app.status.name,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              app.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(app.status.name),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    trailing: const Icon(
                      Icons.chevron_right,
                    ),

                    onTap: () => _openDetails(app),
                  ),
                ),
              ),

            if (appVM.applications.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Only one Student Assistant application is allowed per student.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}