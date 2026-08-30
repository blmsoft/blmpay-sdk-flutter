import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'blmpay_exception.dart';

class BlmPayClient {
  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  BlmPayClient({required this.apiKey,this.baseUrl = 'https://pay.blmtec.co.tz/api/v1',this.timeout = const Duration(seconds: 30),http.Client? httpClient,}) : _http = httpClient ?? http.Client() {
    if (apiKey.trim().isEmpty) throw ArgumentError('BLMPay apiKey is required.');
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

  Future<Map<String,dynamic>> _request(String method,String path,{Map<String,dynamic>? body,Map<String,dynamic>? query,String? idempotencyKey}) async {
    var uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
    if (query != null && query.isNotEmpty) { final q = <String,String>{}; query.forEach((key,value){ if(value != null && value.toString().isNotEmpty) q[key]=value.toString(); }); uri = uri.replace(queryParameters:q); }
    final headers=<String,String>{'Authorization':'Bearer $apiKey','Accept':'application/json'};
    if(body != null) headers['Content-Type']='application/json';
    if(idempotencyKey != null && idempotencyKey.trim().isNotEmpty) headers['Idempotency-Key']=idempotencyKey.trim();
    try {
      late http.Response response;
      switch(method){case 'POST': response=await _http.post(uri,headers:headers,body:body==null?null:jsonEncode(body)).timeout(timeout); break; case 'DELETE': response=await _http.delete(uri,headers:headers,body:body==null?null:jsonEncode(body)).timeout(timeout); break; default: response=await _http.get(uri,headers:headers).timeout(timeout);}
      dynamic decoded; try { decoded=jsonDecode(response.body); } catch (_) { throw BlmPayException('BLMPay returned invalid JSON.',statusCode:response.statusCode,response:response.body); }
      final data=decoded is Map<String,dynamic>?decoded:Map<String,dynamic>.from(decoded as Map);
      if(response.statusCode<200 || response.statusCode>=300){throw BlmPayException((data['message']??'BLMPay request failed.').toString(),statusCode:response.statusCode,errorCode:data['error_code']?.toString(),response:data);}
      return data;
    } on TimeoutException { throw const BlmPayException('BLMPay request timed out.'); } on BlmPayException { rethrow; } catch(e){ throw BlmPayException('BLMPay connection failed.',response:e); }
  }
  void close() => _http.close();
}
