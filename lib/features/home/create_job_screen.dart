import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:rentr_workflow/core/constants/job_status.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  Future<void> createJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'agentId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),

        // 🔴 JOB STATUS — IMPORTANT
        'status': JobStatus.open.value,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create job")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Job")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Job Title"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: "Job Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : createJob,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create Job"),
            ),
          ],
        ),
      ),
    );
  }
}
