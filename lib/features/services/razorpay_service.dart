import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  final Function(String paymentId) onSuccess;
  final Function(String error) onError;
  final Function(String wallet) onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onError,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required int amount, // paise
    required String jobId,
    required String description,
    required String customerName,
    required String customerEmail,
  }) {
    var options = {
      'key': 'rzp_test_S6fMZdP5A3ZyDv', // 🔴 STEP 2.4 la change pannuva
      'amount': amount,
      'name': 'RentR',
      'description': description,
      'prefill': {
        'contact': '9999999999',
        'email': customerEmail,
      },
      'notes': {
        'jobId': jobId,
      },
    };

    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess(response.paymentId!);
  }

  void _handleError(PaymentFailureResponse response) {
    onError(response.message ?? 'Payment Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet(response.walletName ?? '');
  }

  void dispose() {
    _razorpay.clear();
  }
}
