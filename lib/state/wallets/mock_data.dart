import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';

const String mockWalletId = '0x0000000';

final CWWallet mockWallet = CWWallet(
  10000,
  name: 'Citizen Coin',
  address: '0x0000000',
  symbol: 'CC',
);

final List<CWWallet> mockWallets = [
  CWWallet(
    10000,
    name: 'Citizen Coin',
    address: '0x0000000',
    symbol: 'CC',
  ),
  CWWallet(
    7999,
    name: 'Another Coin',
    address: '0x0000000',
    symbol: 'AC',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
  CWWallet(
    10000,
    name: 'Coin',
    address: '0x0000000',
    symbol: 'C',
  ),
];

final List<CWTransaction> mockTransactions = [
  CWTransaction(
    1000,
    id: '0',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    38,
    id: '1',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    2342,
    id: '2',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    323,
    id: '3',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    542,
    id: '4',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    9923,
    id: '5',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    33,
    id: '6',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
  CWTransaction(
    343,
    id: '7',
    chainId: 0,
    from: '0x1234567890',
    to: '0x1234567890',
    title: 'Deposit',
    date: DateTime.now(),
  ),
];
