import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_models.dart';
import '../../models/product.dart';
import '../../providers/admin/admin_category_provider.dart';
import '../../providers/admin/admin_product_provider.dart';
import 'admin_widgets.dart';

class AdminProductFormScreen extends StatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, this.productId});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _sku = TextEditingController();
  final _price = TextEditingController();
  final _originalPrice = TextEditingController();
  final _description = TextEditingController();
  final _material = TextEditingController();
  final _care = TextEditingController();
  final _tag = TextEditingController();

  String? _categoryId;
  String _status = RecordStatusX.active;
  bool _isSummer = false;
  bool _isFeatured = false;

  String? _productId;
  bool _loading = false;
  bool _busyImage = false;

  bool get _isEditing => _productId != null;

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_productId != null) await _loadProduct();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _slug, _sku, _price, _originalPrice, _description, _material, _care, _tag]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    final product = await context.read<AdminProductProvider>().fetchProduct(_productId!);
    if (!mounted) return;

    if (product != null) {
      _name.text = product.name;
      _slug.text = product.slug;
      _sku.text = product.sku;
      _price.text = product.price.toStringAsFixed(0);
      _originalPrice.text = product.originalPrice?.toStringAsFixed(0) ?? '';
      _description.text = product.description ?? '';
      _material.text = product.material ?? '';
      _care.text = product.careInstructions ?? '';
      _tag.text = product.tag ?? '';
      _categoryId = product.categoryId;
      _status = product.status.toUpperCase();
      _isSummer = product.isSummer;
      _isFeatured = product.isFeatured;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      adminToast(context, 'Phải chọn danh mục cho sản phẩm.', success: false);
      return;
    }

    final provider = context.read<AdminProductProvider>();
    final price = double.tryParse(_price.text.trim().replaceAll(',', '')) ?? 0;
    final original = _originalPrice.text.trim().isEmpty
        ? null
        : double.tryParse(_originalPrice.text.trim().replaceAll(',', ''));

    if (_isEditing) {
      final ok = await adminRun(
        context,
        provider,
        () => provider.updateProduct(
          _productId!,
          name: _name.text,
          slug: _slug.text,
          sku: _sku.text,
          price: price,
          originalPrice: original,
          description: _description.text,
          material: _material.text,
          careInstructions: _care.text,
          tag: _tag.text,
          thumbnail: null,
          isSummer: _isSummer,
          isFeatured: _isFeatured,
          status: _status,
          categoryId: _categoryId,
        ),
        successMessage: 'Đã lưu sản phẩm.',
      );
      if (ok && mounted) await _loadProduct();
      return;
    }

    final newId = await provider.createProduct(
      name: _name.text,
      slug: _slug.text,
      sku: _sku.text,
      price: price,
      originalPrice: original,
      description: _description.text,
      material: _material.text,
      careInstructions: _care.text,
      tag: _tag.text,
      isSummer: _isSummer,
      isFeatured: _isFeatured,
      status: _status,
      categoryId: _categoryId!,
    );

    if (!mounted) return;

    if (newId == null) {
      adminToast(context, provider.errorMessage ?? 'Không tạo được sản phẩm.', success: false);
      return;
    }

    adminToast(context, 'Đã tạo sản phẩm. Thêm ảnh và tồn kho ở dưới.');
    setState(() => _productId = newId);
    await _loadProduct();
  }

  Future<void> _pickImage(Future<bool> Function(String path) action, String successMessage) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null || !mounted) return;

    final provider = context.read<AdminProductProvider>();
    setState(() => _busyImage = true);
    await adminRun(context, provider, () => action(picked.path), successMessage: successMessage);
    if (mounted) setState(() => _busyImage = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProductProvider>();
    final categories = context.watch<AdminCategoryProvider>().selectable;
    final product = _isEditing ? provider.selected : null;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: Text(_isEditing ? 'SỬA SẢN PHẨM' : 'THÊM SẢN PHẨM'),
        actions: [
          TextButton(
            onPressed: provider.isLoading ? null : _save,
            child: const Text('LƯU', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _card(
                        title: 'THÔNG TIN',
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AdminField(controller: _name, label: 'Tên sản phẩm', required: true),
                              AdminField(
                                controller: _slug,
                                label: 'Slug',
                                helper: 'Để trống thì máy chủ tự sinh từ tên.',
                                validator: (value) {
                                  final v = (value ?? '').trim();
                                  if (v.isEmpty) return null;
                                  return RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(v)
                                      ? null
                                      : 'Chỉ chữ thường, số và dấu gạch ngang';
                                },
                              ),
                              AdminField(
                                controller: _sku,
                                label: 'SKU',
                                required: true,
                                helper: 'Mã nội bộ, phải khác mọi sản phẩm hiện có.',
                              ),
                              AdminField(
                                controller: _price,
                                label: 'Giá bán (đ)',
                                required: true,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final v = double.tryParse((value ?? '').trim().replaceAll(',', ''));
                                  if (v == null) return 'Nhập số';
                                  return v > 0 ? null : 'Giá phải lớn hơn 0';
                                },
                              ),
                              AdminField(
                                controller: _originalPrice,
                                label: 'Giá gốc (đ)',
                                keyboardType: TextInputType.number,
                                helper: 'Để trống nếu không giảm giá.',
                                validator: (value) {
                                  final raw = (value ?? '').trim();
                                  if (raw.isEmpty) return null;
                                  final v = double.tryParse(raw.replaceAll(',', ''));
                                  if (v == null) return 'Nhập số';
                                  return v > 0 ? null : 'Giá gốc phải lớn hơn 0';
                                },
                              ),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                                decoration: const InputDecoration(
                                  labelText: 'Danh mục *',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: categories
                                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName)))
                                    .toList(),
                                onChanged: (value) => setState(() => _categoryId = value),
                                validator: (value) => value == null ? 'Phải chọn danh mục' : null,
                              ),
                              const SizedBox(height: 14),
                              AdminField(controller: _tag, label: 'Nhãn', hint: 'VD: Signature'),
                              AdminField(controller: _description, label: 'Mô tả', maxLines: 4),
                              AdminField(controller: _material, label: 'Chất liệu', maxLines: 2),
                              AdminField(controller: _care, label: 'Hướng dẫn bảo quản', maxLines: 2),
                              DropdownButtonFormField<String>(
                                initialValue: RecordStatusX.editable.contains(_status)
                                    ? _status
                                    : RecordStatusX.active,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: RecordStatusX.editable
                                    .map((s) =>
                                        DropdownMenuItem(value: s, child: Text(RecordStatusX.label(s))))
                                    .toList(),
                                onChanged: (value) => setState(() => _status = value ?? _status),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sản phẩm "Đang bán" buộc phải có ảnh bìa. Chưa có ảnh thì máy chủ '
                                'sẽ giữ sản phẩm ở trạng thái ẩn.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              SwitchListTile(
                                value: _isSummer,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Hàng hè', style: TextStyle(fontSize: 13.5)),
                                onChanged: (value) => setState(() => _isSummer = value),
                              ),
                              SwitchListTile(
                                value: _isFeatured,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Nổi bật trên trang chủ',
                                    style: TextStyle(fontSize: 13.5)),
                                onChanged: (value) => setState(() => _isFeatured = value),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Lưu ý: ô để trống nghĩa là GIỮ NGUYÊN giá trị cũ, không phải xoá — '
                                'đây là quy ước cập nhật một phần của máy chủ.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isEditing)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text(
                            'Lưu thông tin trước, sau đó mới thêm được ảnh và tồn kho (cần có mã '
                            'sản phẩm do máy chủ sinh).',
                            style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 14),
                        _buildImageSection(product),
                        const SizedBox(height: 14),
                        _buildStockSection(product),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mute, letterSpacing: 0.8),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildImageSection(AdminProduct? product) {
    final gallery = product?.gallery ?? const <AdminProductImage>[];
    final thumbnail = product?.thumbnail;

    return _card(
      title: 'ẢNH',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gallery.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Chưa có ảnh nào. Thêm ít nhất một ảnh rồi chọn làm ảnh bìa để sản phẩm được bán.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemCount: gallery.length,
              itemBuilder: (context, index) {
                final image = gallery[index];
                final isThumb = thumbnail != null && thumbnail == image.imageUrl;
                return _galleryTile(image, isThumb, gallery.length);
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busyImage
                      ? null
                      : () => _pickImage(
                            (path) => context.read<AdminProductProvider>().addImage(_productId!, path),
                            'Đã thêm ảnh.',
                          ),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Thêm ảnh', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busyImage
                      ? null
                      : () => _pickImage(
                            (path) =>
                                context.read<AdminProductProvider>().uploadThumbnail(_productId!, path),
                            'Đã đặt ảnh bìa mới.',
                          ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Tải ảnh bìa', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
          if (_busyImage)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Đang tải ảnh lên...', style: TextStyle(fontSize: 12, color: AppColors.mute)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _galleryTile(AdminProductImage image, bool isThumbnail, int galleryCount) {
    final path = Product.resolveImage(image.imageUrl);
    final isNetwork = path.startsWith('http');
    final placeholder = Container(color: AppColors.sand100);

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.expand(
                  child: isNetwork
                      ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
                      : Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
                ),
              ),
              if (isThumbnail)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.clay500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('BÌA',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 17, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    final provider = context.read<AdminProductProvider>();
                    switch (value) {
                      case 'thumb':
                        await adminRun(
                          context,
                          provider,
                          () => provider.selectThumbnail(_productId!, image.id),
                          successMessage: 'Đã đặt làm ảnh bìa.',
                        );
                      case 'replace':
                        await _pickImage(
                          (p) => provider.replaceImage(_productId!, image.id, p),
                          'Đã thay ảnh.',
                        );
                      case 'delete':
                        final ok = await adminConfirm(
                          context,
                          title: 'Xoá ảnh này?',
                          message: galleryCount <= 1
                              ? 'Đây là ảnh cuối cùng. Máy chủ sẽ từ chối nếu sản phẩm đang được bán — '
                                  'hãy chuyển sản phẩm sang trạng thái ẩn trước.'
                              : 'Ảnh sẽ bị xoá khỏi thư viện của sản phẩm.',
                        );
                        if (!ok || !mounted) return;
                        await adminRun(
                          context,
                          provider,
                          () => provider.removeImage(_productId!, image.id),
                          successMessage: 'Đã xoá ảnh.',
                        );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'thumb', child: Text('Đặt làm ảnh bìa')),
                    PopupMenuItem(value: 'replace', child: Text('Thay ảnh khác')),
                    PopupMenuItem(value: 'delete', child: Text('Xoá ảnh')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSection(AdminProduct? product) {
    final variants = product?.variants ?? const <AdminVariant>[];
    final missing = product?.missingSizes ?? const <String>[];

    return _card(
      title: 'TỒN KHO THEO SIZE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (variants.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Chưa khai size nào. Khách không đặt được hàng khi sản phẩm chưa có size với số '
                'lượng tồn.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
              ),
            )
          else
            ...variants.map(_variantRow),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: missing
                  .map((size) => OutlinedButton(
                        onPressed: () => _addVariant(size),
                        child: Text('+ Size $size', style: const TextStyle(fontSize: 12.5)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Tổng tồn: ${product?.totalStock ?? 0} sản phẩm',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _variantRow(AdminVariant variant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sand100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(variant.size,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Còn ${variant.stockQuantity}',
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.clay600,
            onPressed: () => _editStock(variant),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade600,
            onPressed: () => _removeVariant(variant),
          ),
        ],
      ),
    );
  }

  Future<void> _addVariant(String size) async {
    final controller = TextEditingController(text: '0');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Thêm size $size'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số lượng tồn',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Thôi')),
          ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('THÊM')),
        ],
      ),
    );

    final stock = int.tryParse(controller.text.trim()) ?? 0;
    controller.dispose();
    if (submitted != true || !mounted) return;

    final provider = context.read<AdminProductProvider>();
    await adminRun(
      context,
      provider,
      () => provider.addVariant(_productId!, size: size, stock: stock),
      successMessage: 'Đã thêm size $size.',
    );
  }

  Future<void> _editStock(AdminVariant variant) async {
    final controller = TextEditingController(text: variant.stockQuantity.toString());
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tồn kho size ${variant.size}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng tồn',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu có người khác vừa sửa cùng size này, máy chủ sẽ từ chối để tránh ghi đè số '
              'liệu kho. Lúc đó chỉ cần tải lại và sửa lại.',
              style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Thôi')),
          ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('LƯU')),
        ],
      ),
    );

    final stock = int.tryParse(controller.text.trim());
    controller.dispose();
    if (submitted != true || stock == null || !mounted) return;

    final provider = context.read<AdminProductProvider>();
    await adminRun(
      context,
      provider,
      () => provider.updateVariant(
        _productId!,
        variant.id,
        stock: stock,
        expectedVersion: variant.version,
      ),
      successMessage: 'Đã cập nhật tồn kho.',
    );
  }

  Future<void> _removeVariant(AdminVariant variant) async {
    final ok = await adminConfirm(
      context,
      title: 'Xoá size ${variant.size}?',
      message: 'Khách sẽ không chọn được size này nữa.',
    );
    if (!ok || !mounted) return;

    final provider = context.read<AdminProductProvider>();
    await adminRun(
      context,
      provider,
      () => provider.removeVariant(_productId!, variant.id),
      successMessage: 'Đã xoá size ${variant.size}.',
    );
  }
}
