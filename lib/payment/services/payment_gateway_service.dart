import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:http/http.dart' as http;

/// سرویس درگاه پرداخت
class PaymentGatewayService {
  factory PaymentGatewayService() => _instance;
  PaymentGatewayService._internal();
  static final PaymentGatewayService _instance =
      PaymentGatewayService._internal();

  final http.Client _client = http.Client();

  /// درخواست پرداخت از زیبال
  Future<Map<String, dynamic>?> requestZibalPayment({
    required int amount,
    required String description,
    required String callbackUrl,
    String? orderId,
    String? mobile,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'درخواست پرداخت زیبال - مبلغ: ${PaymentConstants.formatAmount(amount)}',
        );
      }

      // بررسی اعتبار مبلغ
      if (!PaymentConstants.isValidAmount(amount)) {
        throw Exception(PaymentConstants.invalidAmount);
      }

      final url = Uri.parse(
        '${PaymentConstants.zibalBaseUrl}${PaymentConstants.zibalRequestEndpoint}',
      );

      final requestBody = {
        'merchant': AppConfig.zibalMerchantId,
        'amount': amount,
        'description': description,
        'callbackUrl': callbackUrl,
        'apiKey': AppConfig.zibalApiKey, // اضافه کردن API Key
        if (orderId != null) 'orderId': orderId,
        if (mobile != null) 'mobile': mobile,
        if (metadata != null) 'metadata': metadata,
      };

      if (kDebugMode) {
        print('ارسال درخواست به زیبال: ${jsonEncode(requestBody)}');
      }

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(PaymentConstants.connectionTimeout);

      if (kDebugMode) {
        print('پاسخ زیبال: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['result'] == 100) {
          return {
            'success': true,
            'trackId': responseData['trackId'],
            'payUrl':
                'https://gateway.zibal.ir/start/${responseData['trackId']}',
            'message': 'درخواست پرداخت با موفقیت ایجاد شد',
          };
        } else {
          final errorMessage =
              PaymentConstants.zibalStatusCodes[responseData['result']] ??
              'خطای نامشخص';
          return {
            'success': false,
            'error': errorMessage,
            'code': responseData['result'],
          };
        }
      } else {
        throw HttpException('خطا در درخواست: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در درخواست پرداخت زیبال: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// تایید پرداخت زیبال
  Future<Map<String, dynamic>?> verifyZibalPayment({
    required String trackId,
  }) async {
    try {
      if (kDebugMode) {
        print('تایید پرداخت زیبال - trackId: $trackId');
      }

      final url = Uri.parse(
        '${PaymentConstants.zibalBaseUrl}${PaymentConstants.zibalVerifyEndpoint}',
      );

      final requestBody = {
        'merchant': AppConfig.zibalMerchantId,
        'trackId': trackId,
      };

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(PaymentConstants.connectionTimeout);

      if (kDebugMode) {
        print('پاسخ تایید زیبال: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        final resultCode = responseData['result'];
        if (resultCode == 100 || resultCode == 201) {
          return {
            'success': true,
            'amount': responseData['amount'],
            'refNumber': responseData['refNumber'],
            'cardNumber': responseData['cardNumber'],
            'status': responseData['status'],
            'message': 'پرداخت با موفقیت تایید شد',
          };
        } else {
          final errorMessage =
              PaymentConstants.zibalStatusCodes[resultCode] ?? 'خطای نامشخص';
          return {'success': false, 'error': errorMessage, 'code': resultCode};
        }
      } else {
        throw HttpException('خطا در تایید: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید پرداخت زیبال: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// استعلام وضعیت پرداخت زیبال
  Future<Map<String, dynamic>?> inquiryZibalPayment({
    required String trackId,
  }) async {
    try {
      final url = Uri.parse(
        '${PaymentConstants.zibalBaseUrl}${PaymentConstants.zibalInquiryEndpoint}',
      );

      final requestBody = {
        'merchant': AppConfig.zibalMerchantId,
        'trackId': trackId,
      };

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(PaymentConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': responseData};
      } else {
        throw HttpException('خطا در استعلام: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در استعلام پرداخت زیبال: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// درخواست پرداخت از زرین‌پال
  Future<Map<String, dynamic>?> requestZarinpalPayment({
    required int amount,
    required String description,
    required String callbackUrl,
    String? mobile,
    String? email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'درخواست پرداخت زرین‌پال - مبلغ: ${PaymentConstants.formatAmount(amount)}',
        );
      }

      // بررسی اعتبار مبلغ
      if (!PaymentConstants.isValidAmount(amount)) {
        throw Exception(PaymentConstants.invalidAmount);
      }

      final url = Uri.parse(
        '${PaymentConstants.zarinpalBaseUrl}${PaymentConstants.zarinpalRequestEndpoint}',
      );

      final requestBody = {
        'merchant_id': AppConfig.zarinpalMerchantId,
        'amount': amount,
        'description': description,
        'callback_url': callbackUrl,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'data': requestBody}),
          )
          .timeout(PaymentConstants.connectionTimeout);

      if (kDebugMode) {
        print('پاسخ زرین‌پال: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;

        if (data['code'] == 100) {
          return {
            'success': true,
            'authority': data['authority'],
            'payUrl':
                'https://www.zarinpal.com/pg/StartPay/${data['authority']}',
            'message': 'درخواست پرداخت با موفقیت ایجاد شد',
          };
        } else {
          final errorMessage =
              PaymentConstants.zarinpalStatusCodes[data['code']] ??
              'خطای نامشخص';
          return {
            'success': false,
            'error': errorMessage,
            'code': data['code'],
          };
        }
      } else {
        throw HttpException('خطا در درخواست: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در درخواست پرداخت زرین‌پال: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// تایید پرداخت زرین‌پال
  Future<Map<String, dynamic>?> verifyZarinpalPayment({
    required String authority,
    required int amount,
  }) async {
    try {
      if (kDebugMode) {
        print('تایید پرداخت زرین‌پال - authority: $authority');
      }

      final url = Uri.parse(
        '${PaymentConstants.zarinpalBaseUrl}${PaymentConstants.zarinpalVerifyEndpoint}',
      );

      final requestBody = {
        'merchant_id': AppConfig.zarinpalMerchantId,
        'authority': authority,
        'amount': amount,
      };

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'data': requestBody}),
          )
          .timeout(PaymentConstants.connectionTimeout);

      if (kDebugMode) {
        print('پاسخ تایید زرین‌پال: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>;

        if (data['code'] == 100 || data['code'] == 101) {
          return {
            'success': true,
            'refId': data['ref_id'],
            'cardHash': data['card_hash'],
            'cardPan': data['card_pan'],
            'message': 'پرداخت با موفقیت تایید شد',
          };
        } else {
          final errorMessage =
              PaymentConstants.zarinpalStatusCodes[data['code']] ??
              'خطای نامشخص';
          return {
            'success': false,
            'error': errorMessage,
            'code': data['code'],
          };
        }
      } else {
        throw HttpException('خطا در تایید: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید پرداخت زرین‌پال: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// پردازش پرداخت با درگاه انتخابی
  Future<Map<String, dynamic>?> processPayment({
    required PaymentTransaction transaction,
    required PaymentGateway gateway,
    required String callbackUrl,
    String? mobile,
    String? email,
  }) async {
    try {
      switch (gateway) {
        case PaymentGateway.zibal:
          return await requestZibalPayment(
            amount: transaction.finalAmount,
            description: transaction.description,
            callbackUrl: callbackUrl,
            orderId: transaction.id,
            mobile: mobile,
            metadata: transaction.metadata,
          );

        case PaymentGateway.zarinpal:
          return await requestZarinpalPayment(
            amount: transaction.finalAmount,
            description: transaction.description,
            callbackUrl: callbackUrl,
            mobile: mobile,
            email: email,
            metadata: transaction.metadata,
          );

        case PaymentGateway.wallet:
          throw Exception(
            'پرداخت از کیف پول باید از طریق WalletService انجام شود',
          );
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش پرداخت: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// تایید پرداخت با درگاه انتخابی
  Future<Map<String, dynamic>?> verifyPayment({
    required PaymentTransaction transaction,
    required PaymentGateway gateway,
    required String gatewayResponse,
    int? amount,
  }) async {
    try {
      switch (gateway) {
        case PaymentGateway.zibal:
          return await verifyZibalPayment(trackId: gatewayResponse);

        case PaymentGateway.zarinpal:
          return await verifyZarinpalPayment(
            authority: gatewayResponse,
            amount: amount ?? transaction.finalAmount,
          );

        case PaymentGateway.wallet:
          throw Exception(
            'تایید پرداخت کیف پول باید از طریق WalletService انجام شود',
          );
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید پرداخت: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// بستن اتصالات
  void dispose() {
    _client.close();
  }
}
