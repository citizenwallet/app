import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';

class CommunityRow extends StatelessWidget {
  final Config config;
  final Function(Config) onTap;
  final Function(String) onInfoTap;

  const CommunityRow({
    super.key,
    required this.config,
    required this.onTap,
    required this.onInfoTap,
  });

  void handleTap() {
    onTap(config);
  }

  void handleInfoTap() {
    onInfoTap(config.community.url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colors.white.withOpacity(0.2),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: config.community.logo.isNotEmpty
                      ? Theme.of(context).colors.white
                      : Theme.of(context).colors.surfacePrimary,
                ),
                child: config.community.logo.isNotEmpty
                    ? kDebugMode
                        ? CoinLogo(
                            size: 50,
                            borderWidth: 0,
                          )
                        : CoinLogo(
                            size: 50,
                            borderWidth: 0,
                            logo: config.community.logo,
                          )
                    : Center(
                        child: Text(
                          config.community.name.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.community.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(context).colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      config.community.description,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: Theme.of(context).colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                onPressed: handleInfoTap,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Icon(
                  CupertinoIcons.info_circle,
                  color: Theme.of(context).colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
