import 'package:flutter/cupertino.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletSessionApprovalModal extends StatefulWidget {
  final SessionProposalEvent? sessionProposal;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const WalletSessionApprovalModal({
    super.key,
    this.sessionProposal,
    required this.onConfirm,
    required this.onCancel,
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Connect to ${widget.sessionProposal?.params.proposer.metadata.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              widget.sessionProposal?.params.proposer.metadata.icons
                          .isNotEmpty ==
                      true
                  ? Image.network(
                      widget.sessionProposal!.params.proposer.metadata.icons
                          .first,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar();
                      },
                    )
                  : _buildInitialsAvatar(),
              const SizedBox(height: 10),
              Text(
                "${widget.sessionProposal?.params.proposer.metadata.name} wants to connect",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final url =
                      widget.sessionProposal?.params.proposer.metadata.url;
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                child: Text(
                  "${widget.sessionProposal?.params.proposer.metadata.url}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.sessionProposal?.params.proposer.metadata.description}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
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

  Widget _buildInitialsAvatar() {
    final name = widget.sessionProposal?.params.proposer.metadata.name ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.systemBlue,
          ),
        ),
      ),
    );
  }
}
