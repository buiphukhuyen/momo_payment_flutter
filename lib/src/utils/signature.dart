import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/payment_info.dart';

/// Tiện ích tạo chữ ký (Signature) bảo mật cho MoMo
class SignatureUtils {
  /// Tạo chữ ký cho yêu cầu thanh toán (Create Payment)
  ///
  /// Công thức:
  /// accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType
  static String generateSignature({
    required MomoPaymentInfo paymentInfo,
    required String partnerCode,
    required String accessKey,
    required String secretKey,
  }) {
    final rawSignature =
        'accessKey=$accessKey&'
        'amount=${paymentInfo.amount}&'
        'extraData=${paymentInfo.extraData}&'
        'ipnUrl=${paymentInfo.ipnUrl}&'
        'orderId=${paymentInfo.orderId}&'
        'orderInfo=${paymentInfo.orderInfo}&'
        'partnerCode=$partnerCode&'
        'redirectUrl=${paymentInfo.redirectUrl}&'
        'requestId=${paymentInfo.requestId}&'
        'requestType=${paymentInfo.requestType}';

    // Ký bằng thuật toán HMAC-SHA256
    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(utf8.encode(rawSignature));

    return digest.toString();
  }

  /// Tạo chữ ký cho yêu cầu kiểm tra trạng thái (Query Status)
  ///
  /// Công thức:
  /// accessKey=$accessKey&orderId=$orderId&partnerCode=$partnerCode&requestId=$requestId
  static String generateQuerySignature({
    required String partnerCode,
    required String accessKey,
    required String secretKey,
    required String orderId,
    required String requestId,
  }) {
    final rawSignature =
        'accessKey=$accessKey&'
        'orderId=$orderId&'
        'partnerCode=$partnerCode&'
        'requestId=$requestId';

    final hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmacSha256.convert(utf8.encode(rawSignature));

    return digest.toString();
  }
}
