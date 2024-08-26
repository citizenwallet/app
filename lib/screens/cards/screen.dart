import 'package:citizenwallet/state/cards/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CardsScreen extends StatefulWidget {
  final WalletLogic walletLogic;

  const CardsScreen({
    super.key,
    required this.walletLogic,
  });

  @override
  CardsScreenState createState() => CardsScreenState();
}

class CardsScreenState extends State<CardsScreen> {
  late CardsLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = CardsLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  void onLoad() async {
    _logic.init();
  }

  void handleAddCard() {
    final wallet = context.read<WalletState>().wallet;
    if (wallet == null) {
      return;
    }

    print(
        '${AppLocalizations.of(context)!.initialAddress} ${widget.walletLogic.privateKey.address.hexEip55}');

    // _logic.configure(
    //     widget.walletLogic.privateKey, wallet.account, wallet.alias);
    _logic.read();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: AppLocalizations.of(context)!.cards,
            actionButton: CupertinoButton(
              padding: const EdgeInsets.all(5),
              onPressed: handleAddCard,
              child: Icon(
                CupertinoIcons.plus,
                color: Theme.of(context).colors.primary.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}
