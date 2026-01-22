import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true) // 🔥 IMPORTANT
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
                  notifications[index].data() as Map<String, dynamic>;

              String title = data['title'] ?? 'Notification';
              String subtitle = data['message'] ?? '';

              // Handle specific notification types for better formatting
              if (data['type'] == 'job_applied') {
                title = 'New Job Application';
                subtitle =
                    '${data['fromUserName']} applied for your job "${data['jobTitle']}"';
              } else if (data['type'] == 'job_assigned') {
                title = 'Job Assigned';
                subtitle =
                    'You have been assigned to "${data['jobTitle']}"';
              } else if (data['type'] == 'job_completed') {
                title = 'Job Completed';
                subtitle =
                    'Your job "${data['jobTitle']}" has been completed';
              } else if (data['type'] == 'job_started') {
                title = 'Job Started';
                subtitle =
                    'Your job "${data['jobTitle']}" has been started';
              } else if (data['type'] == 'payment_success') {
                title = 'Payment Received';
                subtitle = data['message'] ?? 'Payment has been received';
              }

              return ListTile(
                leading: Icon(
                  data['type'] == 'payment_success'
                      ? Icons.check_circle
                      : Icons.notifications,
                  color: data['type'] == 'payment_success'
                      ? Colors.green
                      : Colors.grey,
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitle.isNotEmpty ? subtitle : 'No details available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
