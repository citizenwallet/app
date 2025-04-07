import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/utils/random.dart';

class StatusUpdateRequest {
  final TransactionState status;
  final String uuid = generateRandomId();

  StatusUpdateRequest(this.status);

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'uuid': uuid,
      };
}
