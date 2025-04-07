# Welcome Contributor

## Note of thanks

Citizen Wallet is built by a community of people, by contributing, you are also a part of this community.

Thank you for your contribution! It makes a difference.

## How to add a new language (if you are a developer, see below)

Go to `lib/l10n`.

This folder contains the language files.

Open `app_en.arb`.

Copy it somewhere you can edit text.

At the top of the file, modify the language code:

```
"@@locale": "en", >> "@@locale": "es",
```

Make changes on the right hand side, do not edit the keys.

Don't do ❌:
```
{
  "regarderContrat": "Regarder Contrat",
}
```

Do ✅:
```
{
  "viewContract": "Regarder Contrat",
}
```

When you see something like this: `Failed to send {currencyName}.`

`{currencyName}` will be replaced by the app. Do not translate it!

[Submit a request here](https://citizenwallet.notion.site/196c274a65fc8068a9ade755de1bc54c?pvs=105)

## How to add a new language

Branch out from `main`.

Make a copy of the language file (`lib/l10n/app_en.arb`) with the two letter language code of the language you are translating to.

`app_es.arb` for Spanish.

```
cp app_en.arb app_es.arb
```

At the top of the file, edit the locale:
```
"@@locale": "en", >> "@@locale": "es",
```

When you see something like this: `Failed to send {currencyName}.`

`{currencyName}` it is a variable that will be replaced by the app. Do not translate it!

Add your new language to the bottom of this list in `main.dart`:

```
const supportedLocales = [
  Locale('en'), // English
  Locale('fr'), // French
  Locale('nl'), // Dutch
];
```

Also add it to `timeago`:

```
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('nl', timeago.NlMessages());
```

Make a pull request.