import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createInvoice({
    required String jobId,
    required String agentId,
    required String contractorId,
    required String jobTitle,
    required double amount,
    double tax = 0,
    required DateTime dueDate,
  }) async {
    final totalAmount = amount + tax;

    await _firestore.collection('invoices').add({
      'jobId': jobId,
      'agentId': agentId,
      'contractorId': contractorId,
      'jobTitle': jobTitle,
      'amount': amount,
      'tax': tax,
      'totalAmount': totalAmount,
      'status': 'draft',
      'createdAt': Timestamp.now(),
      'dueDate': Timestamp.fromDate(dueDate),
    });
  }
}
