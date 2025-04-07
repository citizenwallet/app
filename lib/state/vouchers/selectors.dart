import 'package:citizenwallet/state/vouchers/state.dart';

Map<String, Voucher> selectMappedVoucher(VoucherState state) {
  return state.vouchers.fold<Map<String, Voucher>>(
    {},
    (map, voucher) => {
      ...map,
      voucher.address: voucher,
    },
  );
}

List<Voucher> selectVouchers(VoucherState state) {
  return state.vouchers.where((element) => !element.archived).toList();
}
