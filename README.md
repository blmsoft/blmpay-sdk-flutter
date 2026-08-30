# BLMPay Dart / Flutter SDK

Official Dart and Flutter SDK for BLMPay API v1.

## Add from GitHub

Until the pub.dev release is published, add the official repository to `pubspec.yaml`:

```yaml
dependencies:
  blmpay:
    git:
      url: https://github.com/Winnie7676/blmpay-sdk-flutter.git
      ref: main
```

Then run:

```bash
flutter pub get
```

Example:

```dart
final blmpay = BlmPayClient(
  apiKey: const String.fromEnvironment('BLMPAY_API_KEY'),
);

final balance = await blmpay.getBalance();
```

The SDK covers payments, balance, payment links, invoices, payouts, payout fee quotes, supported banks, recipient lookup, webhooks and USDT.

Do not hard-code a live BLMPay merchant secret key in an APK, IPA or public web build. For production customer-facing apps, keep privileged BLMPay credentials on your backend and let the Flutter app call that backend.

OpenAPI: https://github.com/Winnie7676/blmpay-openapi

MIT License. Powered by BLMSoft.
