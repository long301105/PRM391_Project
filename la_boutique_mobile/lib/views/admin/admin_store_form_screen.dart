import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/store.dart';
import '../../providers/admin/admin_store_provider.dart';
import 'admin_widgets.dart';

/// Form tạo / sửa cửa hàng. `store == null` là tạo mới.
class AdminStoreFormScreen extends StatefulWidget {
  final StoreModel? store;
  const AdminStoreFormScreen({super.key, this.store});

  @override
  State<AdminStoreFormScreen> createState() => _AdminStoreFormScreenState();
}

class _AdminStoreFormScreenState extends State<AdminStoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _hours;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _image;
  String _status = 'ACTIVE';
  bool _saving = false;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: s?.storeName ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _hours = TextEditingController(text: s?.openingHours ?? '');
    _lat = TextEditingController(text: s != null ? s.latitude.toString() : '');
    _lng = TextEditingController(text: s != null ? s.longitude.toString() : '');
    _image = TextEditingController(text: s?.imageUrl ?? '');
    _status = (s?.status ?? 'ACTIVE').toUpperCase();
    if (_status == 'DELETED') _status = 'ACTIVE';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _hours.dispose();
    _lat.dispose();
    _lng.dispose();
    _image.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null; // tùy chọn
    if (!RegExp(r'^0\d{9}$').hasMatch(t)) return 'SĐT phải 10 số, bắt đầu bằng 0';
    return null;
  }

  String? _validateCoord(String? v, {required double min, required double max, required String label}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$label không được để trống';
    final d = double.tryParse(t);
    if (d == null) return '$label phải là số';
    if (d < min || d > max) return '$label phải trong khoảng $min..$max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminStoreProvider>();

    // Field tùy chọn rỗng -> KHÔNG gửi (BE pattern SĐT sẽ từ chối chuỗi rỗng; PATCH coi null là không đổi).
    final body = <String, dynamic>{
      'storeName': _name.text.trim(),
      'address': _address.text.trim(),
      'latitude': double.parse(_lat.text.trim()),
      'longitude': double.parse(_lng.text.trim()),
    };
    final phone = _phone.text.trim();
    final hours = _hours.text.trim();
    final image = _image.text.trim();
    if (phone.isNotEmpty) body['phone'] = phone;
    if (hours.isNotEmpty) body['openingHours'] = hours;
    if (image.isNotEmpty) body['imageUrl'] = image;
    if (_isEdit) body['status'] = _status;

    setState(() => _saving = true);
    final ok = await adminRun(
      context,
      provider,
      () => _isEdit ? provider.updateStore(widget.store!.id, body) : provider.createStore(body),
      successMessage: _isEdit ? 'Đã cập nhật cửa hàng.' : 'Đã thêm cửa hàng.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: Text(_isEdit ? 'SỬA CỬA HÀNG' : 'THÊM CỬA HÀNG')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminField(controller: _name, label: 'Tên cửa hàng', required: true),
            AdminField(controller: _address, label: 'Địa chỉ', required: true, maxLines: 2),
            AdminField(
              controller: _phone,
              label: 'Số điện thoại',
              hint: '0901234567',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            AdminField(controller: _hours, label: 'Giờ mở cửa', hint: '08:00 - 22:00'),
            AdminField(
              controller: _lat,
              label: 'Vĩ độ (latitude)',
              required: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) => _validateCoord(v, min: -90, max: 90, label: 'Vĩ độ'),
            ),
            AdminField(
              controller: _lng,
              label: 'Kinh độ (longitude)',
              required: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) => _validateCoord(v, min: -180, max: 180, label: 'Kinh độ'),
            ),
            AdminField(
              controller: _image,
              label: 'URL ảnh (link ngoài)',
              hint: 'https://...',
              helper: 'Dán link ảnh có sẵn trên mạng, không upload file.',
            ),
            if (_isEdit) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _status == 'ACTIVE',
                activeThumbColor: AppColors.clay500,
                title: Text(_status == 'ACTIVE' ? 'Đang hiển thị (ACTIVE)' : 'Đang ẩn (HIDDEN)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Ẩn thì khách không thấy chi nhánh này trên bản đồ',
                    style: TextStyle(fontSize: 12, color: AppColors.mute)),
                onChanged: (v) => setState(() => _status = v ? 'ACTIVE' : 'HIDDEN'),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.clay500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'LƯU THAY ĐỔI' : 'THÊM CỬA HÀNG', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
