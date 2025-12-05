# VNPAY Payment Flutter

Plugin Flutter giúp tích hợp Cổng thanh toán VNPAY (Việt Nam) vào ứng dụng di động một cách dễ dàng. Thư viện này hỗ trợ tạo giao dịch thanh toán và xác minh chữ ký thông qua API của VNPAY.

## ✨ Tính năng

- 🚀 **Tạo URL thanh toán**: Khởi tạo giao dịch thanh toán qua VNPAY với chữ ký HMAC-SHA512
- 🔒 **Bảo mật**: Tự động tạo & xác minh `vnp_SecureHash` để đảm bảo tính toàn vẹn dữ liệu
- ✅ **Xác minh phản hồi**: Kiểm tra chữ ký phản hồi từ VNPAY (Critical Security)
- 📱 **Deeplink Support**: Tự động xử lý callback qua app_links khi người dùng quay lại app
- 🎯 **Mã lỗi đầy đủ**: Bao gồm mô tả chi tiết tất cả 25+ mã lỗi từ VNPAY
- 🇻🇳 **Hỗ trợ Tiếng Việt**: Tích hợp sẵn thông báo lỗi và mô tả bằng tiếng Việt
- 🛠 **Chế độ Debug**: Dễ dàng gỡ lỗi với log chi tiết (Request/Response)

## 🔧 Chuẩn bị

Trước khi bắt đầu, bạn cần chuẩn bị tài khoản VNPAY và cài đặt Sandbox:

1. **Đăng ký Merchant Account**: Truy cập [VNPAY Merchant Portal](https://sandbox.vnpayment.vn/merchantv2/Users/Login.htm) để đăng ký tài khoản và lấy `TMN Code`, `Hash Secret`
2. **Cài đặt Sandbox**: Làm theo [Hướng dẫn Sandbox](https://sandbox.vnpayment.vn/apis/vnpay-demo/) để có hướng dẫn test chi tiết

## 📦 Cài đặt

Chạy lệnh sau để cài đặt phiên bản mới nhất:

```bash
flutter pub add vnpay_payment_flutter
```

Hoặc thêm thủ công vào file `pubspec.yaml`

## ⚙️ Cấu hình

Để xử lý việc quay trở lại ứng dụng từ VNPAY (Deep Link), bạn cần cấu hình cho Android và iOS.

### Android

Mở file `android/app/src/main/AndroidManifest.xml` và thực hiện 2 bước sau:

1. **Thêm quyền truy vấn (Queries)**: Thêm thẻ `<queries>` vào **bên ngoài** thẻ `<application>` (cùng cấp với `<application>`).

```xml
<manifest ...>
    <!-- Thêm đoạn này -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>

    <application ...>
       ...
    </application>
</manifest>
```

2. **Thêm Intent Filter**: Thêm vào bên trong thẻ `<activity>` của `MainActivity` để nhận kết quả trả về từ VNPAY.

```xml
<manifest ...>
  <application ...>
    <activity ...>
      <!-- ... các cấu hình khác ... -->

      <!-- Thêm Intent Filter này cho Deep Link -->
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Thay thế "vnpaypayment" nếu cần -->
        <data android:scheme="vnpaypayment" android:host="return" />
      </intent-filter>

    </activity>
  </application>
</manifest>
```

### iOS

Mở file `ios/Runner/Info.plist` và thêm cấu hình sau:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>vnpaypayment</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Thay thế "vnpaypayment" nếu cần -->
      <string>vnpaypayment</string>
    </array>
  </dict>
</array>
```

## 🎯 Hướng dẫn sử dụng

### 1. Khởi tạo VNPAYPayment

```dart
import 'package:vnpay_payment_flutter/vnpay_payment_flutter.dart';

// Khởi tạo với thông tin từ VNPAY Merchant Portal
final vnpayPayment = VNPAYPayment(
  tmnCode: "TMN_CODE_CỦA_BẠN",           // ⚠️ Thay bằng TMN Code của bạn
  hashSecret: "HASH_SECRET_CỦA_BẠN...",  // ⚠️ Thay bằng Hash Secret của bạn
  isSandbox: true,               // true: Test mode, false: Production
);
```

### 2. Tạo yêu cầu thanh toán

```dart
import 'package:url_launcher/url_launcher.dart';

final now = DateTime.now();
final txnRef = 'ORD_${now.millisecondsSinceEpoch}'; // Mã đơn duy nhất

// Tạo URL thanh toán với HMAC-SHA512 signature
final paymentUrl = vnpayPayment.generatePaymentUrl(
  txnRef: txnRef,                    // Mã đơn hàng (phải duy nhất)
  amount: 100000,                    // Số tiền VND (chia hết cho 100)
  orderInfo: 'Thanh toán đơn hàng #123456',
  returnUrl: 'vnpaypayment://return', // ⚠️ Deeplink scheme (phải khớp config)
  ipAddr: '192.168.1.1',             // IP khách hàng
  orderType: 'billpayment', 
  expireDate: now.add(Duration(minutes: 15)),
);

try {
  if (await canLaunchUrl(Uri.parse(paymentUrl))) {
    // Mở URL thanh toán trong trình duyệt
    await launchUrl(
      Uri.parse(paymentUrl),
      mode: LaunchMode.externalApplication,
    );
  }
} catch (e) {
  print("Lỗi thanh toán: $e");
}
```

### 3. Kiểm tra trạng thái giao dịch

Bạn nên kiểm tra trạng thái giao dịch khi người dùng quay lại ứng dụng (sử dụng `WidgetsBindingObserver` để phát hiện trạng thái `AppLifecycleState.resumed`).

```dart
import 'package:app_links/app_links.dart';

class PaymentPage extends StatefulWidget {
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  late VNPAYPayment vnpayPayment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAppLinks();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
  
    // Lắng nghe deeplink khi app đang chạy
    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('Deeplink received: $uri');
        if (uri.scheme == 'vnpaypayment' && uri.host == 'return') {
          _handlePaymentReturn(uri);
        }
      },
      onError: (err) {
        debugPrint('Deeplink error: $err');
      },
    );
  }

  void _handlePaymentReturn(Uri uri) {
    final params = uri.queryParameters;
  
    // ⚠️ CRITICAL: Xác minh chữ ký (Bắt buộc để bảo vệ chống giả mạo)
    // Nếu signature không hợp lệ => dữ liệu có thể bị tấn công
    final isValid = vnpayPayment.verifyResponse(params);
    if (!isValid) {
      print('❌ Lỗi: Chữ ký không hợp lệ - Có thể dữ liệu bị giả mạo!');
      return;
    }

    // Lấy thông tin chi tiết từ response code của VNPAY
    final responseCode = VNPayResponseCode.getByCode(
      params['vnp_ResponseCode'] ?? '99',
    );

    if (responseCode.isSuccess) {
      print('✅ ${responseCode.message}');
      // Tính số tiền (VNPAY gửi x100)
      print('Số tiền: ${int.parse(params['vnp_Amount'] ?? '0') ~/ 100} VND');
    } else {
      print('❌ ${responseCode.message}');
      print('Chi tiết: ${responseCode.description}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

## 📝 Ví dụ

Xem thư mục `example` để tham khảo mã nguồn ứng dụng mẫu hoàn chỉnh.

```bash
cd example
flutter run
```

Ứng dụng mẫu bao gồm:

- Form nhập thông tin thanh toán
- Khởi tạo giao dịch
- Xử lý deeplink callback
- Hiển thị chi tiết trạng thái giao dịch

## 🤝 Đóng góp

Phát hiện lỗi hoặc có đề xuất? Vui lòng tạo issue hoặc pull request tại GitHub.

## 📄 License

MIT License - xem file [LICENSE](LICENSE)

## ⚖️ Tuyên bố miễn trừ trách nhiệm

Gói thư viện này là một triển khai của bên thứ ba và không trực thuộc chính thức VNPAY. Vui lòng tham khảo [Tài liệu API VNPAY chính thức](https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html) để biết thêm chi tiết.
