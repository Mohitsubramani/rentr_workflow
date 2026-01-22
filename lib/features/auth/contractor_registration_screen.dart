import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorRegistrationScreen extends StatefulWidget {
  const ContractorRegistrationScreen({super.key});

  @override
  State<ContractorRegistrationScreen> createState() =>
      _ContractorRegistrationScreenState();
}

class _ContractorRegistrationScreenState
    extends State<ContractorRegistrationScreen> {
  String? selectedExpertise;
  DateTime? selectedExpiryDate;
  DateTime? selectedDOB;
  
  final licenseIdController = TextEditingController();
  final gasSafeLicenseController = TextEditingController();
  final wiapsIdController = TextEditingController();
  final aphcIdController = TextEditingController();

  final List<String> expertise = [
    'Plumber',
    'Gas Repair',
    'Electrician',
    'Heater Repair',
  ];

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedExpiryDate) {
      setState(() {
        selectedExpiryDate = picked;
      });
    }
  }

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

  Future<void> _saveContractorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedExpertise == null || selectedExpiryDate == null || selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate expertise-specific fields
    if (selectedExpertise == 'Gas Repair' && gasSafeLicenseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Gas Safe License ID')),
      );
      return;
    }

    if ((selectedExpertise == 'Plumber' || selectedExpertise == 'Heater Repair') &&
        wiapsIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter WIAPS ID')),
      );
      return;
    }

    if (selectedExpertise == 'Electrician' && aphcIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter APHC/CPS ID')),
      );
      return;
    }

    // Build contractor data
    final contractorData = {
      'role': 'contractor',
      'email': user.email,
      'expertise': selectedExpertise,
      'dateOfBirth': selectedDOB,
      'licenseExpiryDate': selectedExpiryDate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add expertise-specific credentials
    if (selectedExpertise == 'Gas Repair') {
      contractorData['gasSafeLicenseId'] = gasSafeLicenseController.text.trim();
    } else if (selectedExpertise == 'Plumber' || selectedExpertise == 'Heater Repair') {
      contractorData['wiapsId'] = wiapsIdController.text.trim();
    } else if (selectedExpertise == 'Electrician') {
      contractorData['aphcCpsId'] = aphcIdController.text.trim();
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(contractorData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration completed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    licenseIdController.dispose();
    gasSafeLicenseController.dispose();
    wiapsIdController.dispose();
    aphcIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Expertise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Expertise'),
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
            const SizedBox(height: 24),

            const Text(
              'License/ID Expiry Date *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _selectExpiryDate(context),
              child: Text(
                selectedExpiryDate == null
                    ? 'Select Expiry Date'
                    : 'Expiry: ${selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
              ),
            ),
            const SizedBox(height: 24),

            // Conditional fields based on expertise
            if (selectedExpertise == 'Gas Repair') ...[
              const Text(
                'Gas Safe License ID *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gasSafeLicenseController,
                decoration: InputDecoration(
                  labelText: 'Enter Gas Safe License ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (selectedExpertise == 'Plumber' || selectedExpertise == 'Heater Repair') ...[
              const Text(
                'WIAPS ID *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: wiapsIdController,
                decoration: InputDecoration(
                  labelText: 'Enter WIAPS ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (selectedExpertise == 'Electrician') ...[
              const Text(
                'APHC/CPS ID *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aphcIdController,
                decoration: InputDecoration(
                  labelText: 'Enter APHC/CPS ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveContractorInfo,
                child: const Text('Complete Registration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
