![citizen wallet logo](https://github.com/daobrussels/citizenwallet/blob/main/assets/logo.png "citizen wallet logo")

# Citizen Wallet

Receive and send citizen coins to pay at participating events.

Move your leftovers coins to your Citizen Wallet on your smartphone.

[Read more.](https://citizenwallet.xyz/)

# Running the project

## Install Flutter

[Select your platform and follow instructions.](https://docs.flutter.dev/get-started/install)

## Install dependencies

```
flutter pub get
```

## Make .env file

The example includes a test wallet made for the Ganache TestRPC configuration command.

You can use any other configuration that you want.

```
cp .example.env .env
```

## Run project

You will be prompted to pick a platform.

```
flutter run
```

## Running a Ganache TestRPC

```
sudo docker run --detach --publish 8545:8545 trufflesuite/ganache:latest --account "0x429321276245f7d39855c8040f498af9392cafed95e1e4f50d158b2b39faa9cc,100000000000000000000000" --account "0xe1b5da7d6c2009c09dcb30781ec1dc4e9f73598a26b57e742d706102b69a1716,100000000000000000000000" --account "0x45c532f2bcb9a21f1a25b1d739bd9d3d65209e86836f370897c94e2e571ec18d,100000000000000000000000" --chain.chainId 1682515751360 --chain.networkId 1682515751360 --unlock "0x0b772F674eD6fB67C5647Be0fbBd2FBe95156D60" --unlock "0xBa711ff057dfAC08E4568Bb972EeC2313454f55A" --unlock "0x664ce0F7785E4bA5Ff422C77314eF982F193BeF5"
2cf01f52d6254ef24bed71b85253be48351de50b6b23c021863ad14d497249de
```

# Quick links

Links to read more...
