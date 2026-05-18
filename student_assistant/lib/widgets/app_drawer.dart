import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class AppDrawer extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onNewApplication;
  final VoidCallback? onMyApplications;
  final VoidCallback? onProfile;
  final VoidCallback? onAllApplications;
final VoidCallback? onPendingApplications;
final VoidCallback? onApprovedApplications;
final VoidCallback? onRejectedApplications;

  const AppDrawer({
    super.key,
    required this.isAdmin,
    this.onNewApplication,
    this.onMyApplications,
    this.onProfile,
    this.onAllApplications,
    this.onPendingApplications,
    this.onApprovedApplications,
    this.onRejectedApplications,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo,
                    Colors.blue,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        Colors.white24,

                    backgroundImage:
                        profile?.avatarUrl != null
                            ? NetworkImage(
                                profile!.avatarUrl!,
                              )
                            : null,

                    child:
                        profile?.avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 34,
                              )
                            : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    profile?.fullName ??
                        'Unknown User',

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    profile?.email ??
                        'No Email',

                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: Text(
                      isAdmin
                          ? 'ADMIN'
                          : 'STUDENT',

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // DASHBOARD
            ListTile(
              leading: const Icon(
                Icons.dashboard_outlined,
              ),

              title: const Text(
                'Dashboard',
              ),

              onTap: () {
                Navigator.pop(context);
              },
            ),
if (isAdmin) ...[
  ListTile(
    leading: const Icon(
      Icons.assignment_outlined,
    ),

    title: const Text(
      'All Applications',
    ),

    onTap: () {
      Navigator.pop(context);

      if (onAllApplications != null) {
        onAllApplications!();
      }
    },
  ),

  ListTile(
    leading: const Icon(
      Icons.pending_actions_outlined,
      color: Colors.orange,
    ),

    title: const Text(
      'Pending Applications',
    ),

    onTap: () {
      Navigator.pop(context);

      if (onPendingApplications != null) {
        onPendingApplications!();
      }
    },
  ),

  ListTile(
    leading: const Icon(
      Icons.check_circle_outline,
      color: Colors.green,
    ),

    title: const Text(
      'Approved Applications',
    ),

    onTap: () {
      Navigator.pop(context);

      if (onApprovedApplications != null) {
        onApprovedApplications!();
      }
    },
  ),

  ListTile(
    leading: const Icon(
      Icons.cancel_outlined,
      color: Colors.red,
    ),

    title: const Text(
      'Rejected Applications',
    ),

    onTap: () {
      Navigator.pop(context);

      if (onRejectedApplications != null) {
        onRejectedApplications!();
      }
    },
  ),
],
            // STUDENT FEATURES
            if (!isAdmin) ...[
              ListTile(
                leading: const Icon(
                  Icons.add_box_outlined,
                ),

                title: const Text(
                  'New Application',
                ),

                onTap: () {
                  Navigator.pop(context);

                  if (onNewApplication != null) {
                    onNewApplication!();
                  }
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.assignment_outlined,
                ),

                title: const Text(
                  'My Applications',
                ),

                onTap: () {
                  Navigator.pop(context);

                  if (onMyApplications != null) {
                    onMyApplications!();
                  }
                },
              ),
            ],

            // PROFILE
            ListTile(
              leading: const Icon(
                Icons.person_outline,
              ),

              title: const Text(
                'My Profile',
              ),

              onTap: () {
                Navigator.pop(context);

                if (onProfile != null) {
                  onProfile!();
                }
              },
            ),

            const Spacer(),

            const Divider(),

            // LOGOUT
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),

              onTap: () async {
                Navigator.pop(context);

                await authVM.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}