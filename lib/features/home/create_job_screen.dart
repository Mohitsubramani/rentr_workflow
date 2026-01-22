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
  String? selectedExpertise;
  DateTime? selectedTimeline;

  bool isLoading = false;

  final List<String> expertise = [
    'Plumber',
    'Gas Repair',
    'Electrician',
    'Heater Repair',
  ];

  Future<void> _selectTimeline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedTimeline) {
      setState(() {
        selectedTimeline = picked;
      });
    }
  }

  Future<void> createJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedExpertise == null ||
        selectedTimeline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'expertise': selectedExpertise,
        'timeline': selectedTimeline,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title
            const Text(
              'Job Title *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Enter job title",
                hintText: 'e.g., Kitchen Tap Repair, Electrical Wiring',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Required Expertise
            const Text(
              'Required Expertise *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select expertise'),
              value: selectedExpertise,
              items: expertise.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedExpertise = newValue;
                });
              },
            ),
            const SizedBox(height: 24),

            // Timeline
            const Text(
              'Work Timeline *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _selectTimeline(context),
              child: Text(
                selectedTimeline == null
                    ? 'Select Timeline Date'
                    : 'Timeline: ${selectedTimeline!.toLocal().toString().split(' ')[0]}',
              ),
            ),
            const SizedBox(height: 24),

            // Job Description
            const Text(
              'Job Description *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Enter detailed job description",
                hintText: 'Provide specific details about the work needed...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createJob,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Create Job"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
