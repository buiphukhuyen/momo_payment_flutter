import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/payment_info.dart';
import 'models/payment_response.dart';
import 'utils/signature.dart';

/// Lớp chính để xử lý thanh toán MoMo
class MomoPayment {
  /// Mã đối tác (Partner Code) được cung cấp bởi MoMo
  final String partnerCode;

  /// Access Key được cung cấp bởi MoMo
  final String accessKey;

  /// Secret Key được cung cấp bởi MoMo (Dùng để tạo chữ ký)
  final String secretKey;

  /// Chế độ kiểm thử (Test Mode). Mặc định là true.
  /// Nếu true, sẽ gọi đến endpoint test-payment.momo.vn
  final bool isTestMode;

  /// Chế độ debug. Mặc định là false.
  /// Nếu true, sẽ hiển thị log request/response trong console.
  final bool isDebug;

  // Endpoint cho môi trường Production (Thực tế)
  static const String _productionEndpoint =
      'https://payment.momo.vn/v2/gateway/api/create';
  // Endpoint cho môi trường Test (Kiểm thử)
  static const String _testEndpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create';

  // Endpoint kiểm tra trạng thái giao dịch (Production)
  static const String _productionQueryEndpoint =
      'https://payment.momo.vn/v2/gateway/api/query';
  // Endpoint kiểm tra trạng thái giao dịch (Test)
  static const String _testQueryEndpoint =
      'https://test-payment.momo.vn/v2/gateway/api/query';

  MomoPayment({
    required this.partnerCode,
    required this.accessKey,
    required this.secretKey,
    this.isTestMode = true,
    this.isDebug = false,
  });

  /// Tạo yêu cầu thanh toán (Create Payment)
  ///
  /// [info] chứa thông tin chi tiết về đơn hàng.
  /// Trả về [MomoPaymentResponse] chứa đường dẫn thanh toán (payUrl).
  Future<MomoPaymentResponse> createPayment(MomoPaymentInfo info) async {
    // Đảm bảo requestId được tạo nếu chưa có
    final paymentInfo = MomoPaymentInfo(
      orderId: info.orderId,
      orderInfo: info.orderInfo,
      amount: info.amount,
      redirectUrl: info.redirectUrl,
      ipnUrl: info.ipnUrl,
      extraData: info.extraData,
      requestId: info.requestId ?? const Uuid().v4(),
      requestType: info.requestType,
      autoCapture: info.autoCapture,
      lang: info.lang,
      items: info.items,
      userInfo: info.userInfo,
    );

    // Tạo chữ ký (Signature) bảo mật
    final signature = SignatureUtils.generateSignature(
      paymentInfo: paymentInfo,
      partnerCode: partnerCode,
      accessKey: accessKey,
      secretKey: secretKey,
    );

    final requestBody = paymentInfo.toJson();
    requestBody['partnerCode'] = partnerCode;
    requestBody['signature'] = signature;

    final endpoint = isTestMode ? _testEndpoint : _productionEndpoint;

    try {
      if (isDebug) {
        debugPrint('--- MoMo Create Payment Request ---');
        debugPrint('Endpoint: $endpoint');
        debugPrint('Body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      if (isDebug) {
        debugPrint('--- MoMo Create Payment Response ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MomoPaymentResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to create payment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// Kiểm tra trạng thái giao dịch (Check Transaction Status)
  ///
  /// [orderId] Mã đơn hàng cần kiểm tra.
  /// [requestId] Mã yêu cầu tương ứng.
  Future<MomoPaymentResponse> checkStatus({
    required String orderId,
    required String requestId,
  }) async {
    // Tạo chữ ký cho yêu cầu kiểm tra trạng thái
    final signature = SignatureUtils.generateQuerySignature(
      partnerCode: partnerCode,
      accessKey: accessKey,
      secretKey: secretKey,
      orderId: orderId,
      requestId: requestId,
    );

    final requestBody = {
      'partnerCode': partnerCode,
      'requestId': requestId,
      'orderId': orderId,
      'signature': signature,
      'lang': 'vi',
    };

    final endpoint = isTestMode ? _testQueryEndpoint : _productionQueryEndpoint;

    try {
      if (isDebug) {
        debugPrint('--- MoMo Check Status Request ---');
        debugPrint('Endpoint: $endpoint');
        debugPrint('Body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      if (isDebug) {
        debugPrint('--- MoMo Check Status Response ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MomoPaymentResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to check status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error checking status: $e');
    }
  }

  /// Mở trang thanh toán MoMo trên trình duyệt hoặc ứng dụng MoMo
  ///
  /// [url] Đường dẫn thanh toán (payUrl) nhận được từ [createPayment].
  Future<void> openPaymentPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
