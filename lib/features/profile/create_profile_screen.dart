import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProfileScreen extends StatelessWidget {
  const CreateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    Future<void> saveProfile() async {
      if (user == null) return;
      if (nameController.text.trim().isEmpty) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Profile'),
            )
          ],
        ),
      ),
    );
  }
}
