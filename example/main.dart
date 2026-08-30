import 'package:blmpay/blmpay.dart';

Future<void> main() async {
  const key = String.fromEnvironment('BLMPAY_API_KEY');
  final blmpay = BlmPayClient(apiKey: key);
  print(await blmpay.getBalance());
  blmpay.close();
}
