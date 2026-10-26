import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_models.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../providers/admin/admin_collection_provider.dart';
import '../../providers/admin/admin_product_provider.dart';
import 'admin_widgets.dart';

class AdminCollectionFormScreen extends StatefulWidget {
  final String? collectionId;

  const AdminCollectionFormScreen({super.key, this.collectionId});

  @override
  State<AdminCollectionFormScreen> createState() => _AdminCollectionFormScreenState();
}

class _AdminCollectionFormScreenState extends State<AdminCollectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();

  String? _collectionId;
  bool _loading = false;
  bool _busyCover = false;

  final List<String> _selectedProductIds = [];
  final Map<String, String> _selectedNames = {};

  bool get _isEditing => _collectionId != null;

  @override
  void initState() {
    super.initState();
    _collectionId = widget.collectionId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AdminProductProvider>().fetchProducts(size: 100);
      if (_collectionId != null) await _load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final collection = await context.read<AdminCollectionProvider>().fetchCollection(_collectionId!);
    if (!mounted) return;

    if (collection != null) {
      _name.text = collection.collectionName;
      _slug.text = collection.slug;
      _selectedProductIds
        ..clear()
        ..addAll(collection.products.map((p) => p.productId));
      _selectedNames.clear();
      for (final p in collection.products) {
        _selectedNames[p.productId] = p.productName;
      }
    }
    setState(() => _loading = false);
  }

  CollectionModel? get _current =>
      _isEditing ? context.read<AdminCollectionProvider>().selected : null;

  int? get _version => _current?.version;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProductIds.isEmpty) {
      adminToast(context, 'Bộ sưu tập phải có ít nhất một sản phẩm.', success: false);
      return;
    }

    final provider = context.read<AdminCollectionProvider>();

    if (!_isEditing) {
      final newId = await provider.createCollection(
        collectionName: _name.text,
        slug: _slug.text,
        productIds: _selectedProductIds,
      );
      if (!mounted) return;

      if (newId == null) {
        adminToast(context, provider.errorMessage ?? 'Không tạo được bộ sưu tập.', success: false);
        return;
      }

      adminToast(context, 'Đã tạo bộ sưu tập. Tải ảnh bìa rồi cho hiện ở shop.');
      setState(() => _collectionId = newId);
      await _load();
      return;
    }

    final version = _version;
    if (version == null) {
      adminToast(context, 'Thiếu số hiệu phiên bản. Hãy tải lại bộ sưu tập.', success: false);
      return;
    }

    final okInfo = await provider.updateCollection(
      _collectionId!,
      expectedVersion: version,
      collectionName: _name.text,
      slug: _slug.text,
    );

    if (!mounted) return;
    if (!okInfo) {
      adminToast(context, provider.errorMessage ?? 'Không lưu được thông tin.', success: false);
      return;
    }

    final nextVersion = provider.selected?.version;
    if (nextVersion != null) {
      final okProducts = await provider.replaceProducts(
        _collectionId!,
        expectedVersion: nextVersion,
        productIds: _selectedProductIds,
      );
      if (!mounted) return;
      if (!okProducts) {
        adminToast(
          context,
          provider.errorMessage ?? 'Đã lưu thông tin nhưng chưa lưu được danh sách sản phẩm.',
          success: false,
        );
        return;
      }
    }

    adminToast(context, 'Đã lưu bộ sưu tập.');
    await _load();
  }

  Future<void> _uploadCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null || !mounted) return;

    final provider = context.read<AdminCollectionProvider>();
    setState(() => _busyCover = true);
    await adminRun(
      context,
      provider,
      () => provider.uploadCover(_collectionId!, picked.path),
      successMessage: 'Đã cập nhật ảnh bìa.',
    );
    if (mounted) setState(() => _busyCover = false);
  }

  Future<void> _togglePublish() async {
    final provider = context.read<AdminCollectionProvider>();
    final collection = _current;
    final version = collection?.version;
    if (collection == null || version == null) return;

    if (collection.isActive) {
      await adminRun(
        context,
        provider,
        () => provider.hide(collection.id, expectedVersion: version),
        successMessage: 'Đã ẩn bộ sưu tập. Giờ có thể sửa nội dung.',
      );
      return;
    }

    if (!collection.hasCover) {
      adminToast(context, 'Phải có ảnh bìa trước khi cho hiện ở shop.', success: false);
      return;
    }

    await adminRun(
      context,
      provider,
      () => provider.publish(collection.id, expectedVersion: version),
      successMessage: 'Bộ sưu tập đã hiện ở shop.',
    );
  }

  Future<void> _pickProducts() async {
    final products = context.read<AdminProductProvider>().pageData.items;
    if (products.isEmpty) {
      adminToast(context, 'Chưa tải được danh sách sản phẩm.', success: false);
      return;
    }

    final chosen = Set<String>.from(_selectedProductIds);

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Chọn sản phẩm'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              children: [
                Text(
                  'Đã chọn ${chosen.length} sản phẩm',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final selected = chosen.contains(product.id);
                      return CheckboxListTile(
                        value: selected,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${product.statusText} · SKU ${product.sku.isEmpty ? '—' : product.sku}',
                          style: const TextStyle(fontSize: 11, color: AppColors.mute),
                        ),
                        onChanged: (value) => setDialogState(() {
                          if (value == true) {
                            chosen.add(product.id);
                            _selectedNames[product.id] = product.name;
                          } else {
                            chosen.remove(product.id);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Thôi')),
            ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('XONG')),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    setState(() {
      _selectedProductIds
        ..clear()
        ..addAll(chosen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCollectionProvider>();
    final collection = _isEditing ? provider.selected : null;
    final isActive = collection?.isActive ?? false;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: Text(_isEditing ? 'SỬA BỘ SƯU TẬP' : 'THÊM BỘ SƯU TẬP'),
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
                if (_isEditing && isActive)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFF8E1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Color(0xFF8D6E00)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Bộ đang hiện ở shop. Máy chủ yêu cầu ẩn bộ trước khi sửa nội dung.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8D6E00), height: 1.35),
                          ),
                        ),
                        TextButton(
                          onPressed: _togglePublish,
                          child: const Text('ẨN BỘ', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
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
                              AdminField(
                                controller: _name,
                                label: 'Tên bộ sưu tập',
                                required: true,
                                hint: 'VD: La Boutique Sunset SS26',
                              ),
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
                              if (_isEditing)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Phiên bản dữ liệu: ${collection?.version ?? '—'}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _card(
                        title: 'SẢN PHẨM TRONG BỘ',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedProductIds.isEmpty)
                              const Text(
                                'Chưa chọn sản phẩm nào. Bộ sưu tập phải có ít nhất một sản phẩm.',
                                style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedProductIds
                                    .map((id) => Chip(
                                          label: Text(
                                            _selectedNames[id] ?? id,
                                            style: const TextStyle(fontSize: 11.5),
                                          ),
                                          onDeleted: () =>
                                              setState(() => _selectedProductIds.remove(id)),
                                        ))
                                    .toList(),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _pickProducts,
                              icon: const Icon(Icons.playlist_add, size: 18),
                              label: const Text('Chọn sản phẩm', style: TextStyle(fontSize: 12.5)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Lưu sẽ THAY toàn bộ danh sách của bộ bằng những gì đang chọn ở đây.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 14),
                        _card(
                          title: 'ẢNH BÌA',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (collection?.hasCover == true)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: _coverImage(collection!),
                                  ),
                                )
                              else
                                const Text(
                                  'Chưa có ảnh bìa. Bắt buộc phải có ảnh bìa mới cho bộ hiện ra shop.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _busyCover ? null : _uploadCover,
                                icon: _busyCover
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.image_outlined, size: 18),
                                label: Text(
                                  collection?.hasCover == true ? 'Thay ảnh bìa' : 'Tải ảnh bìa',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _card(
                          title: 'HIỂN THỊ',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AdminStatusChip(
                                    RecordStatusX.label(collection?.status),
                                    tone: isActive ? 1 : 2,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isActive
                                          ? 'Khách đang thấy bộ này ở shop.'
                                          : 'Bộ này chưa hiện ở shop.',
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? AppColors.sand300 : AppColors.clay500,
                                    foregroundColor: isActive ? AppColors.ink : Colors.white,
                                  ),
                                  onPressed: _togglePublish,
                                  child: Text(isActive ? 'ẨN KHỎI SHOP' : 'CHO HIỆN Ở SHOP'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text(
                            'Lưu bộ trước, sau đó mới tải được ảnh bìa và cho hiện ở shop.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                          ),
                        ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _coverImage(CollectionModel collection) {
    final path = Product.resolveImage(collection.coverImageUrl);
    final placeholder = Container(color: AppColors.sand100);
    return path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
        : Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
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
}
