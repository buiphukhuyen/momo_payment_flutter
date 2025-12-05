/// Thông tin chi tiết về đơn hàng thanh toán
class MomoPaymentInfo {
  /// Mã đơn hàng (Duy nhất cho mỗi giao dịch)
  final String orderId;

  /// Thông tin đơn hàng (Hiển thị trên ứng dụng MoMo)
  final String orderInfo;

  /// Số tiền thanh toán (VND)
  final int amount;

  /// URL chuyển hướng sau khi thanh toán xong (App-to-App hoặc Web)
  final String redirectUrl;

  /// URL nhận thông báo kết quả thanh toán (Instant Payment Notification)
  final String ipnUrl;

  /// Dữ liệu kèm theo (Base64 encoded JSON hoặc String)
  final String extraData;

  /// Mã yêu cầu (Duy nhất cho mỗi lần gọi API)
  final String? requestId;

  /// Loại yêu cầu (Mặc định: captureWallet)
  final String requestType;

  /// Tự động capture (Mặc định: true)
  final bool autoCapture;

  /// Ngôn ngữ hiển thị (vi hoặc en)
  final String lang;

  /// Danh sách sản phẩm (Tùy chọn)
  final List<MomoItem>? items;

  /// Thông tin người dùng (Tùy chọn)
  final MomoUserInfo? userInfo;

  MomoPaymentInfo({
    required this.orderId,
    required this.orderInfo,
    required this.amount,
    required this.redirectUrl,
    required this.ipnUrl,
    this.extraData = '',
    this.requestId,
    this.requestType = 'captureWallet',
    this.autoCapture = true,
    this.lang = 'vi',
    this.items,
    this.userInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderInfo': orderInfo,
      'amount': amount,
      'redirectUrl': redirectUrl,
      'ipnUrl': ipnUrl,
      'extraData': extraData,
      'requestId': requestId,
      'requestType': requestType,
      'autoCapture': autoCapture,
      'lang': lang,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      if (userInfo != null) 'userInfo': userInfo!.toJson(),
    };
  }
}

/// Thông tin sản phẩm trong đơn hàng
class MomoItem {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? manufacturer;
  final int price;
  final String currency;
  final int quantity;
  final String? unit;
  final int totalPrice;
  final int? taxAmount;

  MomoItem({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.imageUrl,
    this.manufacturer,
    required this.price,
    this.currency = 'VND',
    required this.quantity,
    this.unit,
    required this.totalPrice,
    this.taxAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (manufacturer != null) 'manufacturer': manufacturer,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      'totalPrice': totalPrice,
      if (taxAmount != null) 'taxAmount': taxAmount,
    };
  }
}

/// Thông tin người dùng thanh toán
class MomoUserInfo {
  final String? name;
  final String? phoneNumber;
  final String? email;

  MomoUserInfo({this.name, this.phoneNumber, this.email});

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
    };
  }
}
