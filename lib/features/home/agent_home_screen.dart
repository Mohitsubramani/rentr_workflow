import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications/notification_screen.dart';
import 'create_job_screen.dart';
import '../services/razorpay_service.dart';
import '../../core/services/email_service.dart';


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

    // Get contractor info for email
    final contractorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(contractorId)
        .get();
    final contractorEmail = contractorDoc.data()?['email'] ?? '';
    final contractorName = contractorDoc.data()?['name'] ?? 'Contractor';

    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'status': 'assigned',
      'assignedTo': contractorId,
    });

    // Send email to contractor
    if (contractorEmail.isNotEmpty) {
      await EmailService.sendJobAssignedEmail(
        contractorEmail: contractorEmail,
        contractorName: contractorName,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        timeline: timeline?.toDate() ?? DateTime.now(),
      );
    }

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

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent Home'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Jobs'),
              Tab(text: 'Completed Jobs'),
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
                        return const Center(
                            child: Text('No active jobs'));
                      }

                      final jobs = snapshot.data!.docs;

                      return ListView.builder(
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

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(job['description'] ?? ''),
                                  const SizedBox(height: 6),
                                  Text('Status: $status'),

                                  if (status == 'applied')
                                    ...appliedBy.map((cid) {
                                      return FutureBuilder<String>(
                                        future:
                                            getContractorName(cid),
                                        builder:
                                            (context, nameSnap) {
                                          final name =
                                              nameSnap.data ??
                                                  'Loading';

                                          return Row(
                                            children: [
                                              Text(name),
                                              const SizedBox(
                                                  width: 8),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    assignContractor(
                                                        doc.id,
                                                        cid),
                                                child: const Text(
                                                    'Assign'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }),

                                  if (status == 'assigned' ||
                                      status == 'in_progress')
                                    FutureBuilder<String>(
                                      future: getContractorName(
                                          job['assignedTo']),
                                      builder: (context, snap) =>
                                          Text(
                                              'Contractor: ${snap.data ?? ''}'),
                                    ),
                                ],
                              ),
                            ),
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
                        return const Center(
                            child: Text('No completed jobs'));
                      }

                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          final job = doc.data()
                              as Map<String, dynamic>;

                          return ListTile(
                            title: Text(job['title'] ?? ''),
                            subtitle:
                                const Text('Job completed'),
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
          // Get contractor info for email
          final contractorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(invoice['contractorId'])
              .get();
          final contractorEmail = contractorDoc.data()?['email'] ?? '';
          final contractorName = contractorDoc.data()?['name'] ?? 'Contractor';

          await FirebaseFirestore.instance
              .collection('invoices')
              .doc(doc.id)
              .update({
            'status': 'paid',
            'paymentId': paymentId,
            'paidAt': Timestamp.now(),
          });

          // Send email to contractor
          if (contractorEmail.isNotEmpty) {
            await EmailService.sendPaymentCompletedEmail(
              contractorEmail: contractorEmail,
              contractorName: contractorName,
              jobTitle: invoice['jobTitle'] ?? 'Job',
              amount: finalAmount,
              paymentId: paymentId,
            );
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
