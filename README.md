<h1 align="center">
  <img src="./assets/wallet.svg"/><br/>
  Citizen Wallet
</h1>

Citizen wallet description...

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
sudo docker run --detach --publish 8545:8545 trufflesuite/ganache:latest --account "0x429321276245f7d39855c8040f498af9392cafed95e1e4f50d158b2b39faa9cc,100000000000000000000" --account "0xe1b5da7d6c2009c09dcb30781ec1dc4e9f73598a26b57e742d706102b69a1716,100000000000000000000"
```

# Quick links

Links to read more...
