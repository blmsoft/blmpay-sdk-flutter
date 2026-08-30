# BLMPay Dart / Flutter SDK

Official SDK foundation for BLMPay API v1, version 0.1.0.

```dart
final blmpay = BlmPayClient(apiKey: const String.fromEnvironment('BLMPAY_API_KEY'));
final balance = await blmpay.getBalance();
```

Covers payments, balance, payment links, invoices, payouts, recipient lookup, webhooks and USDT.

Do not hard-code live API keys in a mobile app. For production merchant apps, keep secret BLMPay API keys on your own backend and let the Flutter app call that backend.

Powered by BLMSoft.
