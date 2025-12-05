# MoMo Payment cho Flutter

Plugin Flutter giúp tích hợp Cổng thanh toán MoMo (Việt Nam) vào ứng dụng di động của bạn một cách dễ dàng. Thư viện này hỗ trợ tạo giao dịch thanh toán và kiểm tra trạng thái giao dịch thông qua REST API của MoMo.

## Tính năng

*   🚀 **Tạo thanh toán (Create Payment)**: Khởi tạo giao dịch thanh toán qua Ứng dụng MoMo hoặc Web.
*   🔍 **Kiểm tra trạng thái (Check Status)**: Xác minh trạng thái giao dịch (Thành công, Thất bại, Đang xử lý).
*   🔗 **Hỗ trợ Deep Link**: Tự động mở ứng dụng MoMo và xử lý quay trở lại ứng dụng (callback) sau khi thanh toán.
*   🛠 **Chế độ Debug**: Dễ dàng gỡ lỗi với log chi tiết (Request/Response).
*   🇻🇳 **Hỗ trợ Tiếng Việt**: Tích hợp sẵn thông báo lỗi và mô tả bằng tiếng Việt.

## Chuẩn bị

Trước khi bắt đầu, bạn cần chuẩn bị tài khoản doanh nghiệp MoMo và cài đặt ứng dụng MoMo Test:

1.  **Đăng ký Hồ sơ doanh nghiệp**: Truy cập [MoMo Merchant Profile](https://developers.momo.vn/v3/vi/docs/payment/onboarding/merchant-profile) để đăng ký tài khoản và lấy `PartnerCode`, `AccessKey`, `SecretKey`.
2.  **Cài đặt ứng dụng Test**: Làm theo [Hướng dẫn Test](https://developers.momo.vn/v3/vi/docs/payment/onboarding/test-instructions) để cài đặt ứng dụng MoMo phiên bản kiểm thử trên thiết bị của bạn.

## Cài đặt

Thêm `momo_payment_flutter` vào file `pubspec.yaml` của bạn:

```yaml
dependencies:
  momo_payment_flutter: ^1.0.0
```

Chạy lệnh sau để tải thư viện:

```bash
flutter pub get
```

## Cấu hình

Để xử lý việc quay trở lại ứng dụng từ MoMo (Deep Link), bạn cần cấu hình cho Android và iOS.

### Android

Mở file `android/app/src/main/AndroidManifest.xml` và thêm **Intent Filter** sau vào bên trong thẻ `<activity>` của `MainActivity`:

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
        <!-- Thay thế "momopayment" bằng scheme bạn đã đăng ký với MoMo -->
        <data android:scheme="momopayment" android:host="return" />
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
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>momo_payment</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Thay thế "momopayment" bằng scheme bạn đã đăng ký với MoMo -->
      <string>momopayment</string>
    </array>
  </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>momo</string>
</array>
```

## Hướng dẫn sử dụng

### 1. Khởi tạo MomoPayment

```dart
import 'package:momo_payment_flutter/momo_payment_flutter.dart';

final momoPayment = MomoPayment(
  partnerCode: "MÃ_PARTNER_CỦA_BẠN",
  accessKey: "ACCESS_KEY_CỦA_BẠN",
  secretKey: "SECRET_KEY_CỦA_BẠN",
  isTestMode: true, // Đặt là false khi chạy Production (Thực tế)
  isDebug: true,    // Đặt là true để xem log chi tiết
);
```

### 2. Tạo yêu cầu thanh toán

```dart
final paymentInfo = MomoPaymentInfo(
  orderId: "MÃ_ĐƠN_HÀNG_123456",
  orderInfo: "Thanh toán đơn hàng #123456",
  amount: 50000,
  redirectUrl: "momopayment://return", // Phải khớp với Scheme đã cấu hình
  ipnUrl: "https://your-server.com/ipn",
  requestType: "captureWallet",
  lang: "vi",
);

try {
  final response = await momoPayment.createPayment(paymentInfo);
  if (response.payUrl != null) {
    // Mở ứng dụng MoMo hoặc Web để thanh toán
    await momoPayment.openPaymentPage(response.payUrl!);
  }
} catch (e) {
  print("Lỗi thanh toán: $e");
}
```

### 3. Kiểm tra trạng thái giao dịch

Bạn nên kiểm tra trạng thái giao dịch khi người dùng quay lại ứng dụng (sử dụng `WidgetsBindingObserver` để phát hiện trạng thái `AppLifecycleState.resumed`).

```dart
final response = await momoPayment.checkStatus(
  orderId: "MÃ_ĐƠN_HÀNG_123456",
  requestId: "REQUEST_ID_ĐÃ_DÙNG_KHI_TẠO_THANH_TOÁN",
);

if (response.resultCode == 0) {
  print("Thanh toán thành công!");
} else {
  print("Thanh toán thất bại: ${response.message}");
}
```

## Ví dụ

Xem thư mục `example` để tham khảo mã nguồn ứng dụng mẫu hoàn chỉnh.

## Tuyên bố miễn trừ trách nhiệm

Gói thư viện này là một triển khai của bên thứ ba và không trực thuộc chính thức MoMo (M_Service). Vui lòng tham khảo [Tài liệu API MoMo chính thức](https://developers.momo.vn/) để biết thêm chi tiết.
