import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications/notification_screen.dart';
import 'create_job_screen.dart';
import '../services/razorpay_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../core/services/n8n_webhook_service.dart';


class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  /* ───────── HELPERS ───────── */

  Future<String> getContractorName(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return 'Unknown';
    return doc.data()?['name'] ?? 'Unknown';
  }

  Future<String> getJobName(String jobId) async {
    final doc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();
    if (!doc.exists) return 'Unknown Job';
    return doc.data()?['title'] ?? 'Unknown Job';
  }

  /* ───────── ASSIGN ───────── */

  Future<void> assignContractor(String jobId, String contractorId) async {
    final agent = FirebaseAuth.instance.currentUser;
    if (agent == null) return;

    final jobDoc =
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();

    final jobTitle = jobDoc.data()?['title'] ?? 'Job';
    final jobDescription = jobDoc.data()?['description'] ?? '';
    final timeline = jobDoc.data()?['timeline'] as Timestamp?;

    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'status': 'assigned',
      'assignedTo': contractorId,
    });


    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'job_assigned',
      'toUserId': contractorId,
      'title': 'Job Assigned',
      'message': 'You have been assigned to "$jobTitle"',
      'jobId': jobId,
      'jobTitle': jobTitle,
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }

  Widget _buildBidsSheet(String jobId, List<String> bids) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Contractor Bids',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: bids.length,
              itemBuilder: (context, index) {
                final contractorId = bids[index];
                return FutureBuilder<Map<String, dynamic>>(
                  future: _getContractorDetails(contractorId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LoadingWidget();
                    }
                    final data = snapshot.data!;
                    return ContractorBidCard(
                      contractorName: data['name'] ?? 'Unknown',
                      expertise: data['expertise'] ?? 'Unspecified',
                      rating: (data['avgRating'] ?? 0.0).toDouble(),
                      reviewCount: data['reviewCount'] ?? 0,
                      onAssign: () {
                        assignContractor(jobId, contractorId);
                        Navigator.pop(context);
                      },
                      onReject: () {
                        // Handle rejection if needed
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getContractorDetails(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('contractorId', isEqualTo: uid)
        .get();

    double avgRating = 0;
    if (reviewsSnapshot.docs.isNotEmpty) {
      double total = 0;
      for (var doc in reviewsSnapshot.docs) {
        total += (doc['rating'] ?? 0).toDouble();
      }
      avgRating = total / reviewsSnapshot.docs.length;
    }

    return {
      'name': userDoc.data()?['name'] ?? 'Unknown',
      'expertise': userDoc.data()?['expertise'] ?? 'Unspecified',
      'avgRating': avgRating,
      'reviewCount': reviewsSnapshot.docs.length,
    };
  }

  void _showInvoiceDetails(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> invoice,
    String status,
    double estimatedAmount,
    double agentEditedAmount,
    double finalAmount,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // You can add invoice detail UI here
          ],
        ),
      ),
    );
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent Dashboard'),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Active Jobs', icon: Icon(Icons.work_outline)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
              Tab(text: 'Invoices', icon: Icon(Icons.receipt_long_outlined)),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
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
              icon: const Icon(Icons.logout_outlined),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateJobScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: user == null
            ? const Center(child: Text('User not found'))
            : TabBarView(
                children: [
                  /* ───────── ACTIVE JOBS ───────── */

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .where('agentId', isEqualTo: user.uid)
                        .where('status', whereIn: [
                          'open',
                          'applied',
                          'assigned',
                          'in_progress'
                        ])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.work_outline,
                          title: 'No Active Jobs',
                          subtitle: 'Create your first job to get started',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateJobScreen(),
                              ),
                            );
                          },
                          actionLabel: 'Create Job',
                        );
                      }

                      final jobs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final doc = jobs[index];
                          final job =
                              doc.data() as Map<String, dynamic>;
                          final status = job['status'];

                          final List appliedBy =
                              job['appliedBy'] is List
                                  ? List.from(job['appliedBy'])
                                  : [];

                          return JobCard(
                            title: job['title'] ?? 'Untitled Job',
                            description: job['description'] ?? '',
                            status: status,
                            statusLabel: status
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            onTap: () {
                              // Handle job tap
                            },
                            actions: [
                              if (status == 'applied' && appliedBy.isNotEmpty)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.person, size: 16),
                                  label: const Text('View Bids'),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) =>
                                          _buildBidsSheet(doc.id, appliedBy.cast<String>()),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  /* ───────── COMPLETED JOBS ───────── */

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .where('agentId', isEqualTo: user.uid)
                        .where('status', isEqualTo: 'completed')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.check_circle_outline,
                          title: 'No Completed Jobs',
                          subtitle: 'Your completed jobs will appear here',
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: snapshot.data!.docs.map((doc) {
                          final job = doc.data()
                              as Map<String, dynamic>;

                          return JobCard(
                            title: job['title'] ?? 'Untitled Job',
                            description: job['description'] ?? '',
                            status: 'completed',
                            statusLabel: 'COMPLETED',
                            onTap: () {},
                          );
                        }).toList(),
                      );
                    },
                  ),

                  /* ───────── INVOICES ───────── */

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('invoices')
                        .where('agentId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No invoices'));
                      }

                      final invoices = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final doc = invoices[index];
                          final invoice =
                              doc.data() as Map<String, dynamic>;

                         final String status = (invoice['status'] ?? '').toString();

                          final estimatedAmount =
                              (invoice['estimatedAmount'] ?? 0)
                                  .toDouble();
                          final agentEditedAmount =
                              (invoice['agentEditedAmount'] ?? 0)
                                  .toDouble();
                          final finalAmount =
                              (invoice['amount'] ?? 0)
                                  .toDouble();

                          return Card(
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<String>(
                                    future: getJobName(invoice['jobId']),
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

                                  if (status == 'estimated') ...[
                                    const SizedBox(height: 6),
                                    Text(
                                        'Estimation: ₹$estimatedAmount'),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore
                                                .instance
                                                .collection(
                                                    'invoices')
                                                .doc(doc.id)
                                                .update({
                                              'amount':
                                                  estimatedAmount,
                                              'finalAmount':
                                                  estimatedAmount,
                                              'status': 'unpaid',
                                            });
                                          },
                                          child: const Text(
                                              'Approve'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {
                                            final ctrl =
                                                TextEditingController(
                                                    text:
                                                        estimatedAmount
                                                            .toString());
                                            showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  AlertDialog(
                                                title: const Text(
                                                    'Edit Amount'),
                                                content: TextField(
                                                  controller: ctrl,
                                                  keyboardType:
                                                      TextInputType
                                                          .number,
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed:
                                                        () async {
                                                      final v =
                                                          double.tryParse(
                                                              ctrl
                                                                  .text);
                                                      if (v ==
                                                              null ||
                                                          v <=
                                                              0) return;

                                                     await FirebaseFirestore.instance
    .collection('invoices')
    .doc(doc.id)
    .update({
  'agentEditedAmount': v,

  // 🔥 MUST ADD – contractor UI depends on this
  'amount': v,
  'finalAmount': v,

  'status': 'revised',
  'revisedAt': Timestamp.now(),
});
await FirebaseFirestore.instance
    .collection('notifications')
    .add({
  'type': 'invoice_revised',
  'toUserId': invoice['contractorId'],
  'fromUserId': user.uid,
  'jobId': invoice['jobId'],
  'title': 'Invoice Revised',
  'message': 'Agent revised the amount to ₹$v',
  'createdAt': Timestamp.now(),
  'read': false,
});


                                                      Navigator.pop(
                                                          context);
                                                    },
                                                    child:
                                                        const Text(
                                                            'Send'),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                          child:
                                              const Text('Edit'),
                                        ),
                                      ],
                                    ),
                                  ],

// 🔹 REVISED
if (status == 'revised') ...[
  Text(
    'Waiting contractor approval for ₹$agentEditedAmount',
  ),
],

// 🔹 PENDING
if (status == 'pending') ...[
  const Text(
    'Waiting for contractor estimation',
    style: TextStyle(color: Colors.orange),
  ),
],

// ✅ PAID
if (status == 'paid') ...[
  const Text(
    'Payment Completed',
    style: TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
    ),
  ),
],

// 💰 UNPAID
if (status == 'unpaid') ...[
  ElevatedButton(
    child: Text('Pay ₹$finalAmount'),
    onPressed: () {
      final razorpay = RazorpayService(
        onSuccess: (paymentId) async {
          await FirebaseFirestore.instance
              .collection('invoices')
              .doc(doc.id)
              .update({
            'status': 'paid',
            'paymentId': paymentId,
            'paidAt': Timestamp.now(),
          });

          try {
            await N8nWebhookService.sendEvent(
              event: 'payment_completed',
              payload: {
                'invoiceId': doc.id,
                'jobId': invoice['jobId'],
                'agentId': user.uid,
                'contractorId': invoice['contractorId'],
                'amount': finalAmount,
                'paymentId': paymentId,
              },
            );
          } catch (e) {
            debugPrint('n8n payment_completed failed: $e');
          }


          await FirebaseFirestore.instance
              .collection('notifications')
              .add({
            'type': 'payment_success',
            'toUserId': invoice['contractorId'],
            'fromUserId': user.uid,
            'title': 'Payment Received',
            'message':
                'Payment ₹$finalAmount received for Job ${invoice['jobId']}',
            'jobId': invoice['jobId'],
            'createdAt': Timestamp.now(),
            'read': false,
          });
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
        onExternalWallet: (wallet) {},
      );

      razorpay.openCheckout(
        amount: (finalAmount * 100).toInt(),
        jobId: invoice['jobId'],
        description: 'Payment for job ${invoice['jobId']}',
        customerName: 'Agent',
        customerEmail: user.email ?? '',
      );
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
                  ),
                ],
              ),
      ),
    );
  }
}
