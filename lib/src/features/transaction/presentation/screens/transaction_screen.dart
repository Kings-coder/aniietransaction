import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/amount.dart';
import '../../domain/models/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart' as bloc_state;
import '../widgets/otp_dialog.dart';

/// Main transaction screen for submitting transfers.
/// 
/// Demonstrates:
/// - Amount input with decimal-safe handling
/// - Transaction submission flow
/// - OTP verification dialog
/// - Retry on timeout
/// - Transaction state visualization
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check for pending transactions on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().add(LoadPendingTransactions());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTransaction() {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final amount = Amount.fromString(_amountController.text);
        context.read<TransactionBloc>().add(SubmitTransaction(
          amount: amount,
          recipient: _recipientController.text.isNotEmpty 
              ? _recipientController.text 
              : null,
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : null,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid amount: $e')),
        );
      }
    }
  }

  void _showOtpDialog(String transactionId, RiskChallengeType challengeType) async {
    final otp = await OtpDialog.show(
      context,
      transactionId: transactionId,
      challengeType: challengeType,
    );

    if (otp != null && mounted) {
      context.read<TransactionBloc>().add(VerifyOtp(
        transactionId: transactionId,
        otp: otp,
      ));
    } else if (mounted) {
      context.read<TransactionBloc>().add(CancelOtpVerification(
        transactionId: transactionId,
      ));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _recipientController.clear();
    _descriptionController.clear();
    context.read<TransactionBloc>().add(ResetTransactionState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Demo'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<TransactionBloc>(),
                    child: const TransactionHistoryScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TransactionBloc, bloc_state.TransactionState>(
        listener: (context, state) {
          if (state is bloc_state.TransactionOtpRequired) {
            _showOtpDialog(state.transactionId, state.challengeType);
          } else if (state is bloc_state.OtpVerificationFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.orange,
              ),
            );
            // Re-show OTP dialog
            _showOtpDialog(state.transactionId, state.challengeType);
          } else if (state is bloc_state.PendingTransactionsLoaded) {
            if (state.hasPendingTransactions) {
              _showRecoveryDialog(state);
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                _buildStatusCard(state),
                const SizedBox(height: 24),
                
                // Transaction Form
                _buildTransactionForm(state),
                
                const SizedBox(height: 24),
                
                // Info Card
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bloc_state.TransactionState state) {
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;
    IconData icon = Icons.info_outline;
    String title = 'Ready';
    String? subtitle;
    List<Widget> actions = [];

    if (state is bloc_state.TransactionSubmitting) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.sync;
      title = 'Submitting Transaction...';
      subtitle = 'Please wait while we process your request';
    } else if (state is bloc_state.TransactionVerifyingOtp) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.security;
      title = 'Verifying OTP...';
    } else if (state is bloc_state.TransactionSuccess) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
      title = 'Transaction Successful!';
      subtitle = 'Server ID: ${state.serverTransactionId ?? 'N/A'}';
      actions = [
        TextButton(
          onPressed: _resetForm,
          child: const Text('New Transaction'),
        ),
      ];
    } else if (state is bloc_state.TransactionFailed) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error_outline;
      title = 'Transaction Failed';
      subtitle = state.error;
      actions = [
        if (state.canRetry)
          TextButton(
            onPressed: () {
              context.read<TransactionBloc>().add(
                RetryTransaction(transactionId: state.transactionId),
              );
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: _resetForm,
          child: const Text('Reset'),
        ),
      ];
    } else if (state is bloc_state.TransactionTimeout) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.timer_off;
      title = 'Request Timed Out';
      subtitle = 'The server did not respond in time. You can safely retry.';
      actions = [
        ElevatedButton.icon(
          onPressed: () {
            context.read<TransactionBloc>().add(
              RetryTransaction(transactionId: state.transactionId),
            );
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry Transaction'),
        ),
      ];
    } else if (state is bloc_state.TransactionLoading) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.hourglass_empty;
      title = state.message ?? 'Loading...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (state is bloc_state.TransactionSubmitting || 
                  state is bloc_state.TransactionVerifyingOtp ||
                  state is bloc_state.TransactionLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(textColor),
                  ),
                )
              else
                Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionForm(bloc_state.TransactionState state) {
    final isLoading = state is bloc_state.TransactionSubmitting ||
        state is bloc_state.TransactionVerifyingOtp ||
        state is bloc_state.TransactionLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Send Money',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              try {
                final amount = Amount.fromString(value);
                if (amount.cents <= 0) {
                  return 'Amount must be greater than zero';
                }
              } catch (e) {
                return 'Invalid amount format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Recipient Field
          TextFormField(
            controller: _recipientController,
            decoration: InputDecoration(
              labelText: 'Recipient (optional)',
              hintText: 'Account ID or name',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What is this for?',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          ElevatedButton(
            onPressed: isLoading ? null : _submitTransaction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Submit Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Demo Information',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Mock API randomly returns: SUCCESS (60%), TIMEOUT (20%), OTP REQUIRED (20%)\n'
            '• Use OTP: 123456 for verification\n'
            '• Transactions persist locally for crash recovery\n'
            '• Same transaction ID = idempotent (no duplicate debits)',
            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showRecoveryDialog(bloc_state.PendingTransactionsLoaded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Pending Transactions Found')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The app detected unfinished transactions from a previous session:'),
            const SizedBox(height: 12),
            if (state.awaitingOtpTransactions.isNotEmpty)
              _buildPendingItem(
                '${state.awaitingOtpTransactions.length} awaiting verification',
                Colors.orange,
              ),
            if (state.pendingTransactions.isNotEmpty)
              _buildPendingItem(
                '${state.pendingTransactions.length} in unknown state',
                Colors.blue,
              ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to review and recover these transactions?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              this.context.read<TransactionBloc>().add(ResetTransactionState());
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Use a small delay or post-frame callback to ensure dialog is gone
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (newContext) => BlocProvider.value(
                      value: BlocProvider.of<TransactionBloc>(this.context),
                      child: const PendingTransactionsScreen(),
                    ),
                  ),
                );
              });
            },
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Screen for displaying transaction history.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadTransactionHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: BlocBuilder<TransactionBloc, bloc_state.TransactionState>(
        builder: (context, state) {
          if (state is bloc_state.TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is bloc_state.TransactionHistoryLoaded) {
            if (state.transactions.isEmpty) {
              return const Center(
                child: Text('No transactions yet'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final tx = state.transactions[index];
                return _buildTransactionTile(tx);
              },
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<TransactionBloc>().add(LoadTransactionHistory());
              },
              child: const Text('Load History'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final stateColor = _getStateColor(tx.state);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stateColor.withOpacity(0.2),
          child: Icon(_getStateIcon(tx.state), color: stateColor, size: 20),
        ),
        title: Text(tx.amount.toDisplayString()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx.state.name.toUpperCase(),
              style: TextStyle(color: stateColor, fontSize: 11),
            ),
            Text(
              'ID: ${tx.clientTransactionId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          _formatDate(tx.updatedAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Color _getStateColor(TransactionState state) {
    switch (state) {
      case TransactionState.completed:
        return Colors.green;
      case TransactionState.failed:
      case TransactionState.cancelled:
        return Colors.red;
      case TransactionState.awaitingOtp:
        return Colors.orange;
      case TransactionState.timeout:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getStateIcon(TransactionState state) {
    switch (state) {
      case TransactionState.completed:
        return Icons.check;
      case TransactionState.failed:
        return Icons.close;
      case TransactionState.cancelled:
        return Icons.cancel;
      case TransactionState.awaitingOtp:
        return Icons.security;
      case TransactionState.timeout:
        return Icons.timer_off;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Screen for managing pending transactions (recovery).
class PendingTransactionsScreen extends StatefulWidget {
  const PendingTransactionsScreen({super.key});

  @override
  State<PendingTransactionsScreen> createState() => _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadPendingTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transactions'),
      ),
      body: BlocConsumer<TransactionBloc, bloc_state.TransactionState>(
        listener: (context, state) {
          if (state is bloc_state.TransactionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction completed!'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<TransactionBloc>().add(LoadPendingTransactions());
          }
        },
        builder: (context, state) {
          if (state is bloc_state.TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is bloc_state.PendingTransactionsLoaded) {
            final allPending = [
              ...state.awaitingOtpTransactions,
              ...state.pendingTransactions,
            ];

            if (allPending.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No pending transactions'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allPending.length,
              itemBuilder: (context, index) {
                final tx = allPending[index];
                return _buildPendingTransactionCard(tx);
              },
            );
          }

          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  Widget _buildPendingTransactionCard(Transaction tx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStateBadge(tx.state),
                const Spacer(),
                Text(
                  tx.amount.toDisplayString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Transaction ID: ${tx.clientTransactionId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Created: ${_formatDate(tx.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (tx.state == TransactionState.awaitingOtp)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOtpDialog(tx),
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text('Complete Verification'),
                    ),
                  ),
                if (tx.state == TransactionState.timeout ||
                    tx.state == TransactionState.pending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<TransactionBloc>().add(
                          RetryTransaction(transactionId: tx.clientTransactionId),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    context.read<TransactionBloc>().add(
                      CancelTransaction(transactionId: tx.clientTransactionId),
                    );
                    context.read<TransactionBloc>().add(LoadPendingTransactions());
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateBadge(TransactionState state) {
    Color color;
    String text;
    
    switch (state) {
      case TransactionState.awaitingOtp:
        color = Colors.orange;
        text = 'AWAITING VERIFICATION';
        break;
      case TransactionState.timeout:
        color = Colors.amber;
        text = 'TIMED OUT';
        break;
      case TransactionState.pending:
        color = Colors.blue;
        text = 'PENDING';
        break;
      default:
        color = Colors.grey;
        text = state.name.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOtpDialog(Transaction tx) async {
    final otp = await OtpDialog.show(
      context,
      transactionId: tx.clientTransactionId,
      challengeType: tx.challengeType ?? RiskChallengeType.smsOtp,
    );

    if (otp != null && mounted) {
      context.read<TransactionBloc>().add(VerifyOtp(
        transactionId: tx.clientTransactionId,
        otp: otp,
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
