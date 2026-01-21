import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:rentr_workflow/core/constants/job_status.dart';

class JobApplicantsScreen extends StatelessWidget {
  final String jobId;
  final List<String> applicants;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.applicants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Applicants")),
      body: applicants.isEmpty
          ? const Center(child: Text("No applicants yet"))
          : ListView.builder(
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final contractorId = applicants[index];

                return ListTile(
                  title: Text(contractorId),
                  trailing: ElevatedButton(
                    onPressed: () async {
  // 1️⃣ Assign job
  await FirebaseFirestore.instance
      .collection('jobs')
      .doc(jobId)
      .update({
    'assignedContractorId': contractorId,
    'status': JobStatus.assigned.value,
  });

  // 2️⃣ Create notification for contractor
  await FirebaseFirestore.instance
      .collection('notifications')
      .add({
    'userId': contractorId,
    'title': 'Job Assigned',
    'message': 'You have been assigned a new job',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Navigator.pop(context);
},

                    child: const Text("Assign"),
                  ),
                );
              },
            ),
    );
  }
}
