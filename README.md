<h1 align="center">
  <img style="height: 100px; width: 100px;" src="https://github.com/citizenwallet/citizenwallet/blob/main/assets/logo.png" alt="citizen wallet logo"/><br/>
  Citizen Wallet
</h1>  

<p align="center">An open source wallet for your community currency.</p>

## About this repo

This is the repo for the web/iOS/Android app of the Citizen Wallet (using DART/Flutter).
[See below](#running-the-project) for instructions on how to run it locally.

## About the Citizen Wallet

Our goal is to give communities the tools they need to build a resilient and regenerative economy 👠💪🌱🌻🌳.

It starts with a wallet to enable all of us, citizens, to receive and send the tokens of our communities without any prior knowledge of web3. 

![Citizen Wallet banner](https://github.com/citizenwallet/.github/assets/74358/2d7b214d-7d1c-4042-af18-c8cf9973d3c2)

Read more on our website: [citizenwallet.xyz](https://citizenwallet.xyz/).

### Why yet another crypto wallet?
Existing crypto wallets assume that you are either a technical person (e.g. metamask) or a trader (e.g. Rainbow wallet). Chances are that most of the people in your community do not fit any of those two categories.

That's why we are building the Citizen Wallet, a new category of wallets for everyday people, that just want to receive and send your community token.

### The easiest way to onboard someone to web3
<img width="1237" alt="Screenshot 2023-11-15 at 10 17 12 AM" src="https://github.com/citizenwallet/app/assets/74358/4b2cd189-0652-400c-ba3f-7f921912b284">

- Create a voucher with a QR code
- When the user scans it, it automatically creates a new Citizen Wallet in their mobile browser and redeems the voucher.
- The private key is in local storage and in the URL after the hash, so that it is never sent over the wire and the user can simply bookmark the page to never lose their new wallet
- They can also install the native app and import their web wallet.
- No need to sign in with any social or enter any email or phone number.

### Features

- Send money by creating a QR code 
- Account abstraction with ERC4337
- Subsidized gas fees (the token issuer pays for the gas fees, so that users don't have to)
- Host it on your own (sub)domain (e.g. https://wallet.oak.community)
- Support for Polygon, Optimism and Base

<img width="1238" alt="Screenshot 2023-11-15 at 10 17 44 AM" src="https://github.com/citizenwallet/app/assets/74358/9d250c45-9e90-4504-94e9-31ac83e37487">

## Contributors

- Kevin Sundar Raj
- Xavier Damman
- Guil Is
- Jonas Boury

## Current communities
- https://wallet.regensunite.earth (RGN token on Polygon)
- https://wallet.oak.community (OAK token on Base)
- https://wallet.sfluv.org (SFLuv token on Polygon)
- https://eure.polygon.citizenwallet.xyz (EURe stable coin on Polygon)

Join us on discord to discuss: https://discord.citizenwallet.xyz

## Links
- https://citizenwallet.xyz
- https://discord.citizenwallet.xyz
- https://figma.citizenwallet.xyz
- https://telegram.citizenwallet.xyz
- https://opencollective.com/citizenwallet

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


