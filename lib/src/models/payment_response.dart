/// Phản hồi từ MoMo API
class MomoPaymentResponse {
  /// Mã đối tác
  final String? partnerCode;

  /// Mã yêu cầu
  final String? requestId;

  /// Mã đơn hàng
  final String? orderId;

  /// Số tiền
  final int? amount;

  /// Thời gian phản hồi (ms)
  final int? responseTime;

  /// Thông báo kết quả (Success, Error...)
  final String? message;

  /// Mã kết quả (0 là thành công)
  final int? resultCode;

  /// URL thanh toán (Dùng để mở Web hoặc App MoMo)
  final String? payUrl;

  /// Deep link mở App MoMo (Android)
  final String? deeplink;

  /// URL QR Code
  final String? qrCodeUrl;

  /// Deep link mở Mini App
  final String? deeplinkMiniApp;

  MomoPaymentResponse({
    this.partnerCode,
    this.requestId,
    this.orderId,
    this.amount,
    this.responseTime,
    this.message,
    this.resultCode,
    this.payUrl,
    this.deeplink,
    this.qrCodeUrl,
    this.deeplinkMiniApp,
  });

  factory MomoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MomoPaymentResponse(
      partnerCode: json['partnerCode'],
      requestId: json['requestId'],
      orderId: json['orderId'],
      amount: json['amount'],
      responseTime: json['responseTime'],
      message: json['message'],
      resultCode: json['resultCode'],
      payUrl: json['payUrl'],
      deeplink: json['deeplink'],
      qrCodeUrl: json['qrCodeUrl'],
      deeplinkMiniApp: json['deeplinkMiniApp'],
    );
  }
}
