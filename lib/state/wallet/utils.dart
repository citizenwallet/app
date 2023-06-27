import 'package:citizenwallet/models/transaction.dart';

bool isPendingTransactionId(String id) {
  return id.startsWith('${pendingTransactionId}_');
}
