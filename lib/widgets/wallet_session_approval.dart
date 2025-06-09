import 'package:flutter/cupertino.dart';

class WalletSessionApprovalModal extends StatefulWidget {
  final String uri;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? title;
  final String? message;

  const WalletSessionApprovalModal({
    super.key,
    required this.uri,
    required this.onConfirm,
    required this.onCancel,
    this.title,
    this.message,
  });

  @override
  State<WalletSessionApprovalModal> createState() =>
      _WalletSessionApprovalModalState();
}

class _WalletSessionApprovalModalState
    extends State<WalletSessionApprovalModal> {
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _handleConfirm() {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground.withOpacity(0.95),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title ?? 'Approve Session',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.message ??
                    'Do you want to approve this session?\n${widget.uri}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton.filled(
                    onPressed: _isLoading ? null : _handleConfirm,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
