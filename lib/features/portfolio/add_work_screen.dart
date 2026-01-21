import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cloudinary_service.dart';

class AddWorkScreen extends StatefulWidget {
  const AddWorkScreen({super.key});

  @override
  State<AddWorkScreen> createState() => _AddWorkScreenState();
}

class _AddWorkScreenState extends State<AddWorkScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  File? selectedImage;
  bool isUploading = false;

  // 🔹 Pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // 🔹 Save work (Cloudinary + Firestore)
  Future<void> saveWork() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (titleController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Title required")),
    );
    return;
  }

  if (selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Select an image")),
    );
    return;
  }

  setState(() => isUploading = true);

  try {
    // 1️⃣ Upload to Cloudinary
    final imageUrl =
        await CloudinaryService.uploadImage(selectedImage!);

    if (imageUrl == null) {
      throw Exception("Cloudinary upload failed");
    }

    // 2️⃣ Save to Firestore
    await FirebaseFirestore.instance
        .collection('portfolios')
        .add({
      'contractorId': user.uid,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrls': [imageUrl],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Success → close screen
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  } catch (e) {
    debugPrint("SAVE WORK ERROR: $e");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save work")),
      );
    }
  } finally {
    if (mounted) {
      setState(() => isUploading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Work')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: 'Work Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Work Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 🔹 Image preview + picker
              if (selectedImage != null)
                Image.file(
                  selectedImage!,
                  height: 150,
                  fit: BoxFit.cover,
                ),

              TextButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Select Image'),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isUploading ? null : saveWork,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Save Work'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
