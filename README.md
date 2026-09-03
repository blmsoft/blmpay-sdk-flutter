# BLMPay Dart / Flutter SDK

Official Dart and Flutter SDK for BLMPay API v1.

## Add from GitHub

Until the pub.dev release is published, add the official repository to `pubspec.yaml`:

```yaml
dependencies:
  blmpay:
    git:
      url: https://github.com/blmsoft/blmpay-sdk-flutter.git
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
  integrationOrigin: 'https://api.example.com',
);

final balance = await blmpay.getBalance();
```

## Domain-bound API keys

When `integrationOrigin` is set, the SDK automatically sends:

```http
X-BLMPay-Origin: https://api.example.com
```

Use the same HTTPS host saved on the API key in BLMPay. A mismatched host may return `403 integration_domain_not_allowed`; a restricted key without an identifiable origin may return `403 integration_origin_required`.

Existing legacy API keys that have no configured domain remain backward compatible and can keep working without `integrationOrigin`.

## Important mobile security

Do **not** hard-code a privileged live BLMPay merchant API key in an APK, IPA or public web build. For production customer-facing apps, the recommended architecture is:

1. Flutter app calls your secured backend.
2. Your backend stores the BLMPay API key.
3. Your backend calls BLMPay and sends the configured `X-BLMPay-Origin` automatically via the SDK.

The BLMPay APK review workflow is an additional integration review layer; it does not make embedded secrets safe.

## API coverage

The SDK covers payments, balance, payment links, invoices, payouts, payout fee quotes, supported banks, recipient lookup, webhooks and USDT.

OpenAPI: https://github.com/blmsoft/blmpay-openapi
MCP: https://github.com/blmsoft/blmpay-mcp

MIT License. Powered by BLMSoft.
