import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/state/wallet_connect/state.dart';
import 'package:provider/provider.dart';

class WalletConnectSessionsModal extends StatelessWidget {
  final Function(String) onDisconnect;

  const WalletConnectSessionsModal({
    super.key,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<WalletConnectState>().activeSessions;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Active Sessions'),
      ),
      child: SafeArea(
        child: ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions.values.elementAt(index);
            final topic = sessions.keys.elementAt(index);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.peer?.metadata?.name ?? 'Unknown App',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.peer?.metadata?.url ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => onDisconnect(topic),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
