import 'package:flutter/material.dart';
import 'package:momo_payment_flutter/momo_payment_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Payment Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _partnerCodeController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _amountController = TextEditingController(text: '1000');
  final _orderInfoController = TextEditingController(
    text: 'Thanh toán đơn hàng',
  );

  bool _isTestMode = true;
  bool _isLoading = false;
  String _status = '';
  String? _currentOrderId;
  String? _currentRequestId;
  late MomoPayment _momoPayment;

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự kiện lifecycle của ứng dụng (để xử lý khi quay lại từ app MoMo)
    WidgetsBinding.instance.addObserver(this);
    _updateMomoPayment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _partnerCodeController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    _amountController.dispose();
    _orderInfoController.dispose();
    super.dispose();
  }

  // Cập nhật cấu hình MoMoPayment khi người dùng thay đổi thông tin
  void _updateMomoPayment() {
    _momoPayment = MomoPayment(
      partnerCode: _partnerCodeController.text,
      accessKey: _accessKeyController.text,
      secretKey: _secretKeyController.text,
      isTestMode: _isTestMode,
      isDebug: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi ứng dụng quay trở lại (Resumed), kiểm tra trạng thái giao dịch
    if (state == AppLifecycleState.resumed) {
      _checkPaymentStatus();
    }
  }

  // Kiểm tra trạng thái giao dịch với MoMo
  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null || _currentRequestId == null) return;

    try {
      setState(() {
        _status = 'Đang kiểm tra trạng thái thanh toán...';
      });

      final response = await _momoPayment.checkStatus(
        orderId: _currentOrderId!,
        requestId: _currentRequestId!,
      );

      setState(() {
        if (response.resultCode == 0) {
          _status = 'Thanh toán thành công!\nMessage: ${response.message}';
        } else {
          _status =
              'Thanh toán thất bại.\nResult Code: ${response.resultCode}\nMessage: ${response.message}';
        }
        // Xóa thông tin giao dịch hiện tại để tránh kiểm tra lại
        _currentOrderId = null;
        _currentRequestId = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi kiểm tra trạng thái: $e';
      });
    }
  }

  // Xử lý thanh toán
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Cập nhật cấu hình trước khi thanh toán
    _updateMomoPayment();

    setState(() {
      _isLoading = true;
      _status = 'Đang khởi tạo thanh toán...';
    });

    try {
      final orderId =
          'Partner_Transaction_ID_${DateTime.now().millisecondsSinceEpoch}';
      final requestId = 'Request_ID_${DateTime.now().millisecondsSinceEpoch}';

      _currentOrderId = orderId;
      _currentRequestId = requestId;

      final paymentInfo = MomoPaymentInfo(
        orderId: orderId,
        orderInfo: _orderInfoController.text,
        amount: int.parse(_amountController.text),
        redirectUrl: 'momopayment://return',
        ipnUrl: 'https://example.com/momo_ip',
        extraData: 'eyJza3VzIjoiIn0=',
        requestId: requestId,
        requestType: 'captureWallet',
        lang: 'vi',
      );

      final response = await _momoPayment.createPayment(paymentInfo);

      if (response.payUrl != null) {
        setState(() {
          _status = 'Đã mở trang thanh toán...';
        });
        await _momoPayment.openPaymentPage(response.payUrl!);
      } else {
        setState(() {
          _status =
              'Không nhận được link thanh toán.\nMessage: ${response.message}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Payment Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Danh sách mã lỗi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultCodesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cấu hình kết nối',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _partnerCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Partner Code',
                          hintText: 'Nhập Partner Code',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập Partner Code'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accessKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Access Key',
                          hintText: 'Nhập Access Key',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập Access Key'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secretKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Secret Key',
                          hintText: 'Nhập Secret Key',
                          prefixIcon: Icon(Icons.security),
                        ),
                        obscureText: true,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập Secret Key'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Test Mode'),
                        subtitle: const Text(
                          'Bật để sử dụng endpoint test-payment.momo.vn',
                        ),
                        value: _isTestMode,
                        onChanged: (value) {
                          setState(() {
                            _isTestMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền (VND)',
                          hintText: 'Nhập số tiền cần thanh toán',
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: 'VND',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số tiền';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Số tiền không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orderInfoController,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung đơn hàng',
                          hintText: 'Nhập nội dung thanh toán',
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập nội dung'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _handlePayment,
                  icon: const Icon(Icons.payment),
                  label: const Text(
                    'THANH TOÁN QUA MOMO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              if (_status.isNotEmpty)
                Card(
                  color: Colors.grey[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Màn hình danh sách mã lỗi (Result Codes) ---

class ResultCode {
  final int code;
  final String message;
  final String description;
  final String type;

  ResultCode({
    required this.code,
    required this.message,
    required this.description,
    required this.type,
  });
}

class ResultCodesScreen extends StatelessWidget {
  const ResultCodesScreen({super.key});

  static final List<ResultCode> resultCodes = [
    ResultCode(
      code: 0,
      message: 'Thành công.',
      description: 'Giao dịch thành công.',
      type: 'Success',
    ),
    ResultCode(
      code: 10,
      message: 'Hệ thống đang được bảo trì.',
      description: 'Vui lòng quay lại sau khi bảo trì được hoàn tất.',
      type: 'System error',
    ),
    ResultCode(
      code: 11,
      message: 'Truy cập bị từ chối.',
      description:
          'Cấu hình tài khoản doanh nghiệp không cho phép truy cập. Vui lòng xem lại các thông tin đăng ký và cấu hình trên M4B.',
      type: 'System error',
    ),
    ResultCode(
      code: 12,
      message: 'Phiên bản API không được hỗ trợ.',
      description: 'Vui lòng nâng cấp lên phiên bản mới nhất.',
      type: 'System error',
    ),
    ResultCode(
      code: 13,
      message: 'Xác thực doanh nghiệp thất bại.',
      description:
          'Vui lòng kiểm tra thông tin kết nối (PartnerCode, AccessKey, SecretKey, Signature).',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 20,
      message: 'Yêu cầu sai định dạng.',
      description: 'Kiểm tra định dạng yêu cầu, các tham số còn thiếu.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 21,
      message: 'Số tiền giao dịch không hợp lệ.',
      description: 'Vui lòng kiểm tra số tiền hợp lệ.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 22,
      message: 'Số tiền giao dịch không hợp lệ.',
      description: 'Số tiền không nằm trong giới hạn cho phép.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 40,
      message: 'RequestId bị trùng.',
      description: 'Vui lòng thử lại với một requestId khác.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 41,
      message: 'OrderId bị trùng.',
      description: 'Vui lòng thử lại với một orderId khác.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 42,
      message: 'OrderId không hợp lệ hoặc không tìm thấy.',
      description: 'Vui lòng thử lại với một orderId khác.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 98,
      message: 'QR Code tạo không thành công.',
      description: 'Vui lòng thử lại sau.',
      type: 'System error',
    ),
    ResultCode(
      code: 99,
      message: 'Lỗi không xác định.',
      description: 'Vui lòng liên hệ MoMo để biết thêm chi tiết.',
      type: 'System error',
    ),
    ResultCode(
      code: 1000,
      message: 'Giao dịch đã khởi tạo, chờ xác nhận.',
      description: 'Giao dịch đang chờ người dùng xác nhận thanh toán.',
      type: 'Pending',
    ),
    ResultCode(
      code: 1001,
      message: 'Giao dịch thất bại do không đủ tiền.',
      description: 'Tài khoản người dùng không đủ tiền.',
      type: 'User error',
    ),
    ResultCode(
      code: 1002,
      message: 'Giao dịch bị từ chối bởi nhà phát hành.',
      description: 'Thẻ thanh toán không khả dụng hoặc lỗi kết nối ngân hàng.',
      type: 'User error',
    ),
    ResultCode(
      code: 1003,
      message: 'Giao dịch đã bị hủy.',
      description: 'Giao dịch bị hủy bởi người dùng hoặc timeout.',
      type: 'Merchant error',
    ),
    ResultCode(
      code: 1004,
      message: 'Giao dịch thất bại do vượt quá hạn mức.',
      description: 'Số tiền vượt quá hạn mức thanh toán của người dùng.',
      type: 'User error',
    ),
    ResultCode(
      code: 1005,
      message: 'Giao dịch thất bại do URL/QR hết hạn.',
      description: 'Vui lòng gửi lại yêu cầu thanh toán khác.',
      type: 'System error',
    ),
    ResultCode(
      code: 1006,
      message: 'Người dùng từ chối xác nhận.',
      description: 'Người dùng đã từ chối thanh toán.',
      type: 'User error',
    ),
    ResultCode(
      code: 7000,
      message: 'Giao dịch đang được xử lý.',
      description: 'Vui lòng chờ giao dịch hoàn tất.',
      type: 'Pending',
    ),
    ResultCode(
      code: 9000,
      message: 'Giao dịch được xác nhận thành công.',
      description: 'Giao dịch đã được xác nhận (thanh toán thành công).',
      type: 'Success',
    ),
  ];

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(
      'https://developers.momo.vn/v3/vi/docs/payment/api/result-handling/resultcode',
    );
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Result Codes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Xem tài liệu',
            onPressed: _launchUrl,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: resultCodes.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = resultCodes[index];
          Color color;
          switch (item.type) {
            case 'Success':
              color = Colors.green;
              break;
            case 'Pending':
              color = Colors.orange;
              break;
            case 'User error':
              color = Colors.blue;
              break;
            default:
              color = Colors.red;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(26),
              child: Text(
                '${item.code}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              item.message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.description),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type,
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
