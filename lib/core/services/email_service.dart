import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<void> sendJobAssignedEmail({
    required String contractorEmail,
    required String contractorName,
    required String jobTitle,
    required String jobDescription,
    required DateTime timeline,
  }) async {
    try {
      await _functions.httpsCallable('sendEmail').call({
        'type': 'job_assigned',
        'to': contractorEmail,
        'contractorName': contractorName,
        'jobTitle': jobTitle,
        'jobDescription': jobDescription,
        'timeline': timeline.toIso8601String(),
      });
    } catch (e) {
      print('Error sending job assigned email: $e');
    }
  }

  static Future<void> sendJobStartedEmail({
    required String agentEmail,
    required String agentName,
    required String contractorName,
    required String jobTitle,
  }) async {
    try {
      await _functions.httpsCallable('sendEmail').call({
        'type': 'job_started',
        'to': agentEmail,
        'agentName': agentName,
        'contractorName': contractorName,
        'jobTitle': jobTitle,
      });
    } catch (e) {
      print('Error sending job started email: $e');
    }
  }

  static Future<void> sendJobCompletedEmail({
    required String agentEmail,
    required String agentName,
    required String contractorName,
    required String jobTitle,
  }) async {
    try {
      await _functions.httpsCallable('sendEmail').call({
        'type': 'job_completed',
        'to': agentEmail,
        'agentName': agentName,
        'contractorName': contractorName,
        'jobTitle': jobTitle,
      });
    } catch (e) {
      print('Error sending job completed email: $e');
    }
  }

  static Future<void> sendInvoiceUploadedEmail({
    required String agentEmail,
    required String agentName,
    required String contractorName,
    required String jobTitle,
    required double amount,
  }) async {
    try {
      await _functions.httpsCallable('sendEmail').call({
        'type': 'invoice_uploaded',
        'to': agentEmail,
        'agentName': agentName,
        'contractorName': contractorName,
        'jobTitle': jobTitle,
        'amount': amount,
      });
    } catch (e) {
      print('Error sending invoice uploaded email: $e');
    }
  }

  static Future<void> sendPaymentCompletedEmail({
    required String contractorEmail,
    required String contractorName,
    required String jobTitle,
    required double amount,
    required String paymentId,
  }) async {
    try {
      await _functions.httpsCallable('sendEmail').call({
        'type': 'payment_completed',
        'to': contractorEmail,
        'contractorName': contractorName,
        'jobTitle': jobTitle,
        'amount': amount,
        'paymentId': paymentId,
      });
    } catch (e) {
      print('Error sending payment completed email: $e');
    }
  }
}
