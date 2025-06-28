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
        border: null,
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: sessions.isEmpty
              ? const Center(
                  child: Text(
                    'No active sessions',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions.values.elementAt(index);
                    final topic = sessions.keys.elementAt(index);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey5
                                .resolveFrom(context),
                            width: 0.5,
                          ),
                        ),
                      ),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session.peer?.metadata?.url ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey
                                        .resolveFrom(context),
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
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
