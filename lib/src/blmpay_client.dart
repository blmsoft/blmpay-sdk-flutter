import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'blmpay_exception.dart';

class BlmPayClient {
  final String apiKey;
  late final String baseUrl;
  final Duration timeout;
  late final http.Client _http;
  late final String apiVersion;
  String? _integrationOrigin;
  String? _hmacSecret;

  BlmPayClient({
    required this.apiKey,
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
    String? integrationOrigin,
    String? hmacSecret,
    String? apiVersion,
    http.Client? httpClient,
  }) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('BLMPay apiKey is required.');
    }

    _http = httpClient ?? http.Client();
    _integrationOrigin = _normalizeIntegrationOrigin(integrationOrigin);
    _hmacSecret = (hmacSecret?.trim().isNotEmpty ?? false) ? hmacSecret!.trim() : null;
    this.apiVersion = (apiVersion?.trim().isNotEmpty ?? false)
        ? apiVersion!.trim().toLowerCase()
        : (_hmacSecret != null ? 'v2' : 'v1');

    if (this.apiVersion != 'v1' && this.apiVersion != 'v2') {
      throw ArgumentError('BLMPay apiVersion must be v1 or v2.');
    }
    if (this.apiVersion == 'v2' && _hmacSecret == null) {
      throw ArgumentError('BLMPay hmacSecret is required for API v2.');
    }

    final configuredBase = (baseUrl?.trim().isNotEmpty ?? false)
        ? baseUrl!.trim()
        : 'https://pay.blmtec.co.tz/api/${this.apiVersion}';
    this.baseUrl = configuredBase.replaceFirst(RegExp(r'/$'), '');
  }

  BlmPayClient setIntegrationOrigin(String? integrationOrigin) {
    _integrationOrigin = _normalizeIntegrationOrigin(integrationOrigin);
    return this;
  }

  Future<Map<String, dynamic>> listPayments({Map<String, dynamic>? query}) => _request('GET','/payments',query:query);
  Future<Map<String, dynamic>> getPayment(String reference) => _request('GET','/payments/${Uri.encodeComponent(reference)}');
  Future<Map<String, dynamic>> createPayment(Map<String,dynamic> body,{String? idempotencyKey}) => _request('POST','/payments',body:body,idempotencyKey:idempotencyKey);
  Future<Map<String, dynamic>> getBalance() => _request('GET','/balance');
  Future<Map<String, dynamic>> listPaymentLinks() => _request('GET','/payment-links');
  Future<Map<String, dynamic>> createPaymentLink(Map<String,dynamic> body) => _request('POST','/payment-links',body:body);
  Future<Map<String, dynamic>> listInvoices() => _request('GET','/invoices');
  Future<Map<String, dynamic>> createInvoice(Map<String,dynamic> body) => _request('POST','/invoices',body:body);
  Future<Map<String, dynamic>> listPayouts({Map<String,dynamic>? query}) => _request('GET','/payouts',query:query);
  Future<Map<String, dynamic>> getPayout(String reference) => _request('GET','/payouts/${Uri.encodeComponent(reference)}');
  Future<Map<String, dynamic>> getPayoutFee(int amount,{String channel='mobile'}) => _request('GET','/payouts/fee',query:{'amount':amount,'channel':channel});
  Future<Map<String, dynamic>> listPayoutBanks() => _request('GET','/payouts/banks');
  Future<Map<String, dynamic>> lookupPayoutName(Map<String,dynamic> body) => _request('POST','/payouts/name-lookup',body:body);
  Future<Map<String, dynamic>> createPayout(Map<String,dynamic> body,{required String idempotencyKey}) => _request('POST','/payouts/send',body:body,idempotencyKey:idempotencyKey);
  Future<Map<String, dynamic>> listWebhooks() => _request('GET','/webhooks');
  Future<Map<String, dynamic>> createWebhook(Map<String,dynamic> body) => _request('POST','/webhooks',body:body);
  Future<Map<String, dynamic>> deleteWebhook(int id) => _request('DELETE','/webhooks/$id');
  Future<Map<String, dynamic>> activateUsdt() => _request('POST','/usdt/activate',body:{});
  Future<Map<String, dynamic>> getUsdtAddress() => _request('GET','/usdt/address');
  Future<Map<String, dynamic>> listUsdtTransfers({Map<String,dynamic>? query}) => _request('GET','/usdt/transfers',query:query);
  Future<Map<String, dynamic>> quoteUsdtWithdrawal({required String address,required Object amount,required String idempotencyKey}) => _request('POST','/usdt/withdrawals/quote',body:{'address':address,'amount':amount},idempotencyKey:idempotencyKey);
  Future<Map<String, dynamic>> confirmUsdtWithdrawal(String quoteReference) => _request('POST','/usdt/withdrawals',body:{'quote_reference':quoteReference});

  Future<Map<String,dynamic>> _request(
    String method,
    String path, {
    Map<String,dynamic>? body,
    Map<String,dynamic>? query,
    String? idempotencyKey,
  }) async {
    final httpMethod = method.toUpperCase();
    var uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

    if (query != null && query.isNotEmpty) {
      final q = <String,String>{};
      query.forEach((key,value) {
        if (value != null && value.toString().isNotEmpty) {
          q[key] = value.toString();
        }
      });
      uri = uri.replace(queryParameters:q);
    }

    final rawBody = body == null ? '' : jsonEncode(body);
    final headers = <String,String>{'Accept':'application/json'};

    if (apiVersion == 'v2') {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final nonce = _generateNonce();
      final target = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      final bodyHash = sha256.convert(utf8.encode(rawBody)).toString();
      final canonical = '$httpMethod\n$target\n$timestamp\n$nonce\n$bodyHash';
      final signature = Hmac(sha256, utf8.encode(_hmacSecret!))
          .convert(utf8.encode(canonical))
          .toString();

      headers['Authorization'] = 'BLMPay-HMAC $apiKey';
      headers['X-BLMPay-Timestamp'] = timestamp;
      headers['X-BLMPay-Nonce'] = nonce;
      headers['X-BLMPay-Signature'] = signature;
    } else {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    if (_integrationOrigin != null) {
      headers['X-BLMPay-Origin'] = _integrationOrigin!;
    }
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey.trim();
    }

    try {
      late http.Response response;
      switch (httpMethod) {
        case 'POST':
          response = await _http.post(uri,headers:headers,body:body == null ? null : rawBody).timeout(timeout);
          break;
        case 'DELETE':
          response = await _http.delete(uri,headers:headers,body:body == null ? null : rawBody).timeout(timeout);
          break;
        default:
          response = await _http.get(uri,headers:headers).timeout(timeout);
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw BlmPayException('BLMPay returned invalid JSON.',statusCode:response.statusCode,response:response.body);
      }

      final data = decoded is Map<String,dynamic>
          ? decoded
          : Map<String,dynamic>.from(decoded as Map);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BlmPayException(
          (data['message'] ?? 'BLMPay request failed.').toString(),
          statusCode:response.statusCode,
          errorCode:data['error_code']?.toString(),
          response:data,
        );
      }
      return data;
    } on TimeoutException {
      throw const BlmPayException('BLMPay request timed out.');
    } on BlmPayException {
      rethrow;
    } catch (e) {
      throw BlmPayException('BLMPay connection failed.',response:e);
    }
  }

  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2,'0')).join();
  }

  static String? _normalizeIntegrationOrigin(String? origin) {
    final value = origin?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
      throw ArgumentError('BLMPay integrationOrigin must be a valid HTTPS URL, for example https://example.com.');
    }
    return value;
  }

  void close() => _http.close();
}
