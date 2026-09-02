import 'package:blmpay/blmpay.dart';

Future<void> main() async {
  const key = String.fromEnvironment('BLMPAY_API_KEY');
  const origin = String.fromEnvironment('BLMPAY_INTEGRATION_ORIGIN');

  final blmpay = BlmPayClient(
    apiKey: key,
    integrationOrigin: origin.isEmpty ? null : origin,
  );

  print(await blmpay.getBalance());
  blmpay.close();
}
