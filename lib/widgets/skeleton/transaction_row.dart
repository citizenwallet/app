import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';

class SkeletonTransactionRow extends StatelessWidget {
  const SkeletonTransactionRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: super.key,
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colors.subtle.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 2,
          color: Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        ),
      ),
      child: const Row(
        children: [
          PulsingContainer(
            height: 50,
            width: 50,
            borderRadius: 25,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PulsingContainer(
                  height: 24,
                  width: 100,
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PulsingContainer(
                  height: 24,
                  width: 50,
                ),
                SizedBox(width: 5),
                PulsingContainer(
                  height: 24,
                  width: 40,
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}
