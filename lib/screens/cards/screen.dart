import 'package:citizenwallet/services/nfc/nfc.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({
    super.key,
  });

  @override
  CardsScreenState createState() => CardsScreenState();
}

class CardsScreenState extends State<CardsScreen> {
  late NFCService nfcService;

  @override
  void initState() {
    super.initState();

    nfcService = NFCService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      nfcService.init();
    });
  }

  void handleAddCard() {
    nfcService.read();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: 'Cards',
            actionButton: CupertinoButton(
              padding: const EdgeInsets.all(5),
              onPressed: handleAddCard,
              child: Icon(
                CupertinoIcons.plus,
                color: ThemeColors.primary.resolveFrom(context),
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
