import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final void Function(String paymentId) onSuccess;
  final void Function(String error) onError;
  final void Function(String wallet) onExternalWallet;

  late Razorpay _razorpay;

  RazorpayService({
    required this.onSuccess,
    required this.onError,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  void openCheckout({
    required int amount,
    required String jobId,
    required String description,
    required String customerName,
    required String customerEmail,
  }) {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount,
      'name': customerName,
      'description': description,
      'prefill': {
        'contact': '',
        'email': customerEmail,
      },
      'notes': {
        'jobId': jobId,
      },
    };

    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess(response.paymentId ?? '');
  }

  void _handleError(PaymentFailureResponse response) {
    onError(response.message ?? 'Payment failed');
  }

  void _handleWallet(ExternalWalletResponse response) {
    onExternalWallet(response.walletName ?? '');
  }

  void dispose() {
    _razorpay.clear();
  }
}
