import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

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
  bool _isLoading = false;
  
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

    setState(() => _isLoading = true);
    try {
      final contractorData = {
        'role': 'contractor',
        'email': user.email,
        'expertise': selectedExpertise,
        'dateOfBirth': selectedDOB,
        'licenseExpiryDate': selectedExpiryDate,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (selectedExpertise == 'Gas Repair') {
        contractorData['gasSafeLicenseId'] = gasSafeLicenseController.text.trim();
      } else if (selectedExpertise == 'Plumber' || selectedExpertise == 'Heater Repair') {
        contractorData['wiapsId'] = wiapsIdController.text.trim();
      } else if (selectedExpertise == 'Electrician') {
        contractorData['aphcCpsId'] = aphcIdController.text.trim();
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Contractor Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your credentials and expertise',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Expertise
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Expertise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text(
                        'Select Expertise',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date of Birth
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDOB(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDOB != null
                                  ? '${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}'
                                  : 'Select your date of birth',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: selectedDOB != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // License Expiry Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'License/ID Expiry Date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectExpiryDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF9FAFB),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedExpiryDate != null
                                  ? '${selectedExpiryDate!.day}/${selectedExpiryDate!.month}/${selectedExpiryDate!.year}'
                                  : 'Select expiry date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: selectedExpiryDate != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Conditional fields based on expertise
              if (selectedExpertise == 'Gas Repair') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gas Safe License ID',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gasSafeLicenseController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter your Gas Safe License ID',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              if (selectedExpertise == 'Plumber' || selectedExpertise == 'Heater Repair') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WIAPS ID',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: wiapsIdController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter your WIAPS ID',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              if (selectedExpertise == 'Electrician') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APHC/CPS ID',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: aphcIdController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter your APHC/CPS ID',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Complete Registration Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContractorInfo,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Complete Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
