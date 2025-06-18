import 'package:flutter/cupertino.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletTransactionModal extends StatefulWidget {
  final SessionData? event;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? transactionType;

  const WalletTransactionModal({
    super.key,
    required this.event,
    required this.onConfirm,
    required this.onCancel,
    this.transactionType,
  });

  @override
  State<WalletTransactionModal> createState() => _WalletTransactionModalState();
}

class _WalletTransactionModalState extends State<WalletTransactionModal> {
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  initState() {
    super.initState();
    print(widget.event);
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm Action',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.event?.peer.metadata.url != null) Text("Origin: "),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final url = widget.event?.peer.metadata.url;
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                child: Text(
                  "${widget.event?.peer.metadata.url}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.transactionType != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.lightBackgroundGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    //burn or mint
                    'You are about to ${widget.transactionType}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
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
