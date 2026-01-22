import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../notifications/notification_screen.dart';
import '../portfolio/add_work_screen.dart';
import '../../core/services/email_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';

class ContractorHomeScreen extends StatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  State<ContractorHomeScreen> createState() =>
      _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  int _currentTabIndex = 0;

  // ⭐ REVIEWS
  Stream<QuerySnapshot> getMyReviews(String contractorId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('contractorId', isEqualTo: contractorId)
        .snapshots();
  }

  double calculateAverageRating(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return 0.0;
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['rating'] ?? 0).toDouble();
    }
    return total / snapshot.docs.length;
  }

  // 🧾 INVOICES
  Stream<QuerySnapshot> getMyInvoices(String contractorId) {
    return FirebaseFirestore.instance
        .collection('invoices')
        .where('contractorId', isEqualTo: contractorId)
        .snapshots();
  }

  Future<String> getJobName(String jobId) async {
    final doc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();
    if (!doc.exists) return 'Unknown Job';
    return doc.data()?['title'] ?? 'Unknown Job';
  }

  Future<String?> getContractorExpertise(String contractorId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(contractorId)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['expertise'] as String?;
  }

  // 🟢 APPLY FOR JOB
  Future<void> applyForJob(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['name'] ?? 'Someone';

    final jobDoc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();

    final jobData = jobDoc.data()!;
    final agentId = jobData['agentId'];
    final jobTitle = jobData['title'] ?? 'Job';

    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'status': 'applied',
      'appliedBy': FieldValue.arrayUnion([user.uid]),
    });

    // 🔔 notify agent
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'job_applied',
      'toUserId': agentId,
      'fromUserId': user.uid,
      'fromUserName': userName,
      'title': 'New Job Application',
      'message': '$userName applied for $jobTitle',
      'jobId': jobId,
      'jobTitle': jobTitle,
      'createdAt': Timestamp.now(),
      'read': false,
    });

    // 🧾 create invoice
   await FirebaseFirestore.instance.collection('invoices').doc(jobId).set({
  'jobId': jobId,
  'jobTitle': jobTitle, // 🔥 MUST ADD – idhu illena notification blank
  'agentId': agentId,
  'contractorId': user.uid,
  'amount': 0,
  'status': 'pending',
  'createdAt': Timestamp.now(),
});

  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contractor Home'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Available Jobs'),
              Tab(text: 'My Jobs'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Portfolio'),
              Tab(text: 'Invoices'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),

        floatingActionButton: _currentTabIndex == 3
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddWorkScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,

        body: user == null
            ? const Center(child: Text('User not found'))
            : TabBarView(
                children: [
                  _availableJobs(user),
                  _simpleJobList(user.uid, 'assigned'),
                  _simpleJobList(user.uid, 'in_progress'),
                  _portfolioAndReviews(user.uid),
                  _invoicesTab(user.uid),
                ],
              ),
      ),
    );
  }

  /* ================= AVAILABLE JOBS ================= */

  Widget _availableJobs(User user) {
    return FutureBuilder<String?>(
      future: getContractorExpertise(user.uid),
      builder: (context, expertiseSnapshot) {
        if (expertiseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contractorExpertise = expertiseSnapshot.data;
        
        if (contractorExpertise == null) {
          return const Center(child: Text('Please complete your profile'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .where('status', whereIn: ['open', 'applied'])
              .where('expertise', isEqualTo: contractorExpertise)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No jobs available for your expertise'));
            }

            final jobs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final doc = jobs[index];
                final job = doc.data() as Map<String, dynamic>;

                final appliedBy = job['appliedBy'] ?? [];
                final hasApplied = appliedBy.contains(user.uid);

                return ListTile(
                  title: Text(job['title'] ?? ''),
                  subtitle: Text(job['description'] ?? ''),
                  trailing: hasApplied
                      ? const Text(
                          'Applied',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        )
                      : ElevatedButton(
                          onPressed: () => applyForJob(doc.id),
                          child: const Text('Apply'),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  /* ================= JOB LIST ================= */

  Widget _simpleJobList(String uid, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('assignedTo', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No jobs'));
        }

        final jobs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final job = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(job['description'] ?? ''),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      child: Text(
                        status == 'assigned'
                            ? 'Start Job'
                            : 'Complete Job',
                      ),
                      onPressed: () async {
                        final newStatus = status == 'assigned'
                            ? 'in_progress'
                            : 'completed';

                        // Get agent info for email
                        final agentDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(job['agentId'])
                            .get();
                        final agentEmail = agentDoc.data()?['email'] ?? '';
                        final agentName = agentDoc.data()?['name'] ?? 'Agent';

                        // Get contractor info
                        final contractorDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get();
                        final contractorName = contractorDoc.data()?['name'] ?? 'Contractor';

                        await FirebaseFirestore.instance
                            .collection('jobs')
                            .doc(doc.id)
                            .update({
                          'status': newStatus,
                          if (newStatus == 'completed')
                            'completedAt': Timestamp.now(),
                        });

                        // Send email notification
                        if (newStatus == 'in_progress') {
                          await EmailService.sendJobStartedEmail(
                            agentEmail: agentEmail,
                            agentName: agentName,
                            contractorName: contractorName,
                            jobTitle: job['title'] ?? 'Job',
                          );
                        } else if (newStatus == 'completed') {
                          await EmailService.sendJobCompletedEmail(
                            agentEmail: agentEmail,
                            agentName: agentName,
                            contractorName: contractorName,
                            jobTitle: job['title'] ?? 'Job',
                          );
                        }

                        await FirebaseFirestore.instance
    .collection('notifications')
    .add({
  'type': newStatus == 'in_progress'
      ? 'job_started'
      : 'job_completed',
  'toUserId': job['agentId'],
  'fromUserId': uid,
  
  'jobTitle': job['title'],

  'title': newStatus == 'in_progress'
      ? 'Job Started'
      : 'Job Completed',
  'message': newStatus == 'in_progress'
      ? 'Your job "${job['title']}" has been started'
      : 'Your job "${job['title']}" has been completed',
  'jobId': doc.id,
  'createdAt': Timestamp.now(),
  'read': false,
});

                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* ================= PORTFOLIO + REVIEWS ================= */

  Widget _portfolioAndReviews(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: getMyReviews(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reviews yet'));
        }

        final avg = calculateAverageRating(snapshot.data!);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Average Rating: ${avg.toStringAsFixed(1)} ⭐',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...snapshot.data!.docs.map((doc) {
              final r = doc.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Row(
                    children: List.generate(
                      r['rating'],
                      (_) => const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                    ),
                  ),
                  subtitle: Text(r['review'] ?? ''),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /* ================= INVOICES ================= */

  Widget _invoicesTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: getMyInvoices(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No invoices yet'));
        }

        final invoices = snapshot.data!.docs;

        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final doc = invoices[index];
            final data = doc.data() as Map<String, dynamic>;

            final status = data['status'];
            final amount = (data['amount'] ?? 0).toDouble();
            

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getJobName(data['jobId']),
                      builder: (context, snapshot) {
                        final jobName = snapshot.data ?? 'Loading...';
                        return Text(
                          'Job: $jobName',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text('Status: $status'),
                    const SizedBox(height: 6),
                    Text('Amount: ₹$amount'),
                    const SizedBox(height: 10),

                    if (status == 'paid')
  const Text(
    'Payment received successfully',
    style: TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
    ),
  ),


                    // 🔹 REVISED – AGENT EDITED AMOUNT
if (status == 'revised') ...[
  Text(
    'Agent Revised Amount: ₹${data['agentEditedAmount']}',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.orange,
    ),
  ),
  const SizedBox(height: 8),

  Row(
    children: [
      // ✅ ACCEPT
      ElevatedButton(
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('invoices')
              .doc(doc.id)
              .update({
            'amount': data['agentEditedAmount'],
            'finalAmount': data['agentEditedAmount'],
            'status': 'unpaid',
            'approvedAt': Timestamp.now(),
          });

          await FirebaseFirestore.instance
              .collection('notifications')
              .add({
            'type': 'revised_amount_accepted',
            'toUserId': data['agentId'],
            'fromUserId': uid,
            'title': 'Revised Amount Accepted',
            'message':
                'Contractor accepted revised amount ₹${data['agentEditedAmount']} for Job ${data['jobId']}',
            'jobId': data['jobId'],
            'createdAt': Timestamp.now(),
            'read': false,
          });
        },
        child: const Text('Accept'),
      ),

      const SizedBox(width: 10),

      // ❌ REJECT
      OutlinedButton(
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('invoices')
              .doc(doc.id)
              .update({
            'status': 'estimated',
          });
        },
        child: const Text('Reject'),
      ),
    ],
  ),
],


                    // 🔹 ESTIMATION
                    if (status == 'pending')
                      ElevatedButton(
                        child: const Text('Enter Estimation'),
                        onPressed: () {
                          final ctrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title:
                                  const Text('Enter Estimation'),
                              content: TextField(
                                controller: ctrl,
                                keyboardType:
                                    TextInputType.number,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  child:
                                      const Text('Submit'),
                                  onPressed: () async {
                                    final v =
                                        double.tryParse(ctrl.text);
                                    if (v == null || v <= 0)
                                      return;

                                    await FirebaseFirestore.instance
                                        .collection('invoices')
                                        .doc(doc.id)
                                        .update({
                                      'estimatedAmount': v,
                                      'amount': v,
                                      'status': 'estimated',
                                      'estimatedAt':
                                          Timestamp.now(),
                                    });
                                    final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();

final fromName = userDoc.data()?['name'] ?? 'Contractor';

await FirebaseFirestore.instance.collection('notifications').add({
  'type': 'invoice_estimated',

  // receiver
  'toUserId': data['agentId'],

  // sender
  'fromUserId': uid,
  'fromUserName': fromName,

  // REQUIRED for notification UI
  'title': 'Estimation Submitted',
  'message':
      '$fromName submitted estimation ₹$v for job "${data['jobTitle']}"',

  // metadata
  'jobId': data['jobId'],
  'jobTitle': data['jobTitle'],

  'createdAt': Timestamp.now(),
  'read': false,
});

                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    if (status == 'estimated')
                      const Text(
                        'Waiting for agent approval',
                        style:
                            TextStyle(color: Colors.orange),
                      ),
                      if (status == 'revised') ...[
  const SizedBox(height: 8),

  ElevatedButton(
    child: const Text('Accept Revision'),
    onPressed: () async {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(doc.id)
          .update({
        'status': 'unpaid',
      });

      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'type': 'invoice_revision_accepted',
        'toUserId': data['agentId'],
        'fromUserId': uid,
        'title': 'Revision Accepted',
        'message':
            'Contractor accepted revised amount for Job ${data['jobId']}',
        'jobId': data['jobId'],
        'createdAt': Timestamp.now(),
        'read': false,
      });
    },
  ),

  const SizedBox(height: 6),

  OutlinedButton(
    child: const Text('Reject Revision'),
    onPressed: () async {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(doc.id)
          .update({
        'status': 'estimated',
      });

      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'type': 'invoice_revision_rejected',
        'toUserId': data['agentId'],
        'fromUserId': uid,
        'title': 'Revision Rejected',
        'message':
            'Contractor rejected revised amount for Job ${data['jobId']}',
        'jobId': data['jobId'],
        'createdAt': Timestamp.now(),
        'read': false,
      });
    },
  ),
],

                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
