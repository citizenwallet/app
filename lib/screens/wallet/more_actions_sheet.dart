import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MoreActionsSheet extends StatelessWidget {
  final void Function()? handleSendScreen;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleMint;
  final void Function()? handleVouchers;

  const MoreActionsSheet({
    super.key,
    this.handleSendScreen,
    this.handlePlugin,
    this.handleMint,
    this.handleVouchers,
  });

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final showVouchers =
        context.select(selectShowVouchers) && handleSendScreen != null;

    final showMinter = context.select(selectShowMinter);

    final showPlugins =
        context.select(selectShowPlugins) && handlePlugin != null;

    final navigator = GoRouter.of(context);

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
            minHeight: 100,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (showVouchers)
                _buildSheetItem(context, AppLocalizations.of(context)!.vouchers,
                    icon: CupertinoIcons.ticket,
                    onPressed: () => navigator
                        .pop({'action': 'voucher', 'pluginConfig': null})),
              if (showMinter)
                _buildSheetItem(context, AppLocalizations.of(context)!.mint,
                    icon: CupertinoIcons.hammer,
                    onPressed: () => navigator
                        .pop({'action': 'minter', 'pluginConfig': null})),
              if (showPlugins)
                ...(wallet?.plugins ?? []).map(
                  (plugin) {
                    return _buildSheetItem(
                      context,
                      plugin.name,
                      customIcon: SvgPicture.network(
                        plugin.icon,
                        semanticsLabel: '${plugin.name} icon',
                        height: 30,
                        width: 30,
                        placeholderBuilder: (_) => Icon(
                          CupertinoIcons.arrow_down,
                          size: 30,
                          color: Theme.of(context).colors.primary,
                        ),
                      ),
                      onPressed: () => navigator
                          .pop({'action': 'plugin', 'pluginConfig': plugin}),
                    );
                  },
                )
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildSheetItem(
  BuildContext context,
  String label, {
  IconData? icon,
  Widget? customIcon,
  VoidCallback? onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          customIcon ??
              Icon(icon, color: Theme.of(context).colors.primary, size: 26),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}