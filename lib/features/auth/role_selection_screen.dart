import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'contractor_registration_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  DateTime? selectedDOB;

  Future<void> _selectDOB(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDOB) {
      setState(() {
        selectedDOB = picked;
      });
    }
  }

  Future<void> _selectRole(String role, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    // For agent, save directly and return
    if (role == 'agent') {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': role,
        'email': user.email,
        'dateOfBirth': selectedDOB,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (role == 'contractor') {
      // For contractor, navigate to detailed registration screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ContractorRegistrationScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Date of Birth *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _selectDOB(context),
              child: Text(
                selectedDOB == null
                    ? 'Select Date of Birth'
                    : 'DOB: ${selectedDOB!.toLocal().toString().split(' ')[0]}',
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Your Role',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectRole('agent', context),
              child: const Text('Agent'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectRole('contractor', context),
              child: const Text('Contractor'),
            ),
          ],
        ),
      ),
    );
  }
}
