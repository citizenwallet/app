import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class MoreActionsSheet extends StatelessWidget {
  final bool isHandleSendDefined;

  const MoreActionsSheet({
    super.key,
    this.isHandleSendDefined = false,
  });

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);
    final config = context.select((WalletState state) => state.config);

    final showVouchers = !kIsWeb &&
        wallet?.locked == false &&
        (!loading || !firstLoad) &&
        wallet?.doubleBalance != 0.0 &&
        isHandleSendDefined;

    // TODO: minting

    // TODO: config plugins

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colors.uiBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSheetItem(context, CupertinoIcons.square_arrow_up, 'Share'),
              _buildSheetItem(context, CupertinoIcons.doc_on_doc, 'Copy'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              _buildSheetItem(context, CupertinoIcons.trash, 'Delete'),
              // ... other items ...
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildSheetItem(BuildContext context, IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colors.primary, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
