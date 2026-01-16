import 'package:flutter/material.dart';

import '../../domain/models/transaction.dart';

/// Dialog for OTP verification during risk challenge.
/// 
/// Shows when server returns 403 RISK_CHALLENGE_REQUIRED.
/// After successful verification, the original request is automatically retried.
class OtpDialog extends StatefulWidget {
  final String transactionId;
  final RiskChallengeType challengeType;
  final Function(String otp) onVerify;
  final VoidCallback onCancel;

  const OtpDialog({
    super.key,
    required this.transactionId,
    required this.challengeType,
    required this.onVerify,
    required this.onCancel,
  });

  /// Shows the OTP dialog and returns the entered OTP or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String transactionId,
    required RiskChallengeType challengeType,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpDialog(
        transactionId: transactionId,
        challengeType: challengeType,
        onVerify: (otp) => Navigator.of(context).pop(otp),
        onCancel: () => Navigator.of(context).pop(null),
      ),
    );
  }

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String get _challengeTitle {
    switch (widget.challengeType) {
      case RiskChallengeType.smsOtp:
        return 'SMS Verification Required';
      case RiskChallengeType.emailOtp:
        return 'Email Verification Required';
      case RiskChallengeType.unknown:
        return 'Verification Required';
    }
  }

  String get _challengeDescription {
    switch (widget.challengeType) {
      case RiskChallengeType.smsOtp:
        return 'Please enter the 6-digit code sent to your registered phone number.';
      case RiskChallengeType.emailOtp:
        return 'Please enter the 6-digit code sent to your email address.';
      case RiskChallengeType.unknown:
        return 'Please enter the verification code.';
    }
  }

  void _handleVerify() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      widget.onVerify(_otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _challengeTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _challengeDescription,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'For demo, use: 123456',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the OTP';
                }
                if (value.length != 6) {
                  return 'OTP must be 6 digits';
                }
                if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                  return 'OTP must contain only numbers';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${widget.transactionId.substring(0, 8)}...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerify,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
