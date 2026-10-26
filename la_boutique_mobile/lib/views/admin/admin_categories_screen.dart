import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_models.dart';
import '../../providers/admin/admin_category_provider.dart';
import 'admin_widgets.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  Future<void> _openForm({AdminCategory? category}) async {
    final provider = context.read<AdminCategoryProvider>();
    final nameController = TextEditingController(text: category?.categoryName ?? '');
    final slugController = TextEditingController(text: category?.slug ?? '');
    String status = category?.status ?? RecordStatusX.active;
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminField(
                    controller: nameController,
                    label: 'Tên danh mục',
                    hint: 'VD: Áo',
                    required: true,
                  ),
                  AdminField(
                    controller: slugController,
                    label: 'Slug',
                    hint: 'ao',
                    helper: 'Để trống thì máy chủ tự sinh từ tên. '
                        'Chỉ chữ thường, số và dấu gạch ngang.',
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return null;
                      return RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(v)
                          ? null
                          : 'Chỉ chữ thường, số và dấu gạch ngang';
                    },
                  ),
                  if (category != null)
                    DropdownButtonFormField<String>(
                      initialValue: RecordStatusX.editable.contains(status.toUpperCase())
                          ? status.toUpperCase()
                          : RecordStatusX.active,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: RecordStatusX.editable
                          .map((s) => DropdownMenuItem(value: s, child: Text(RecordStatusX.label(s))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => status = value ?? status),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Thôi'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true);
              },
              child: const Text('LƯU'),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text;
    final slug = slugController.text;
    nameController.dispose();
    slugController.dispose();

    if (submitted != true || !mounted) return;

    await adminRun(
      context,
      provider,
      () => category == null
          ? provider.createCategory(categoryName: name, slug: slug)
          : provider.updateCategory(category.id, categoryName: name, slug: slug, status: status),
      successMessage: category == null ? 'Đã thêm danh mục.' : 'Đã cập nhật danh mục.',
    );
  }

  Future<void> _delete(AdminCategory category) async {
    final provider = context.read<AdminCategoryProvider>();
    final ok = await adminConfirm(
      context,
      title: 'Xoá danh mục ${category.categoryName}?',
      message: 'Máy chủ sẽ từ chối nếu danh mục còn sản phẩm bên trong. '
          'Hãy chuyển những sản phẩm đó sang danh mục khác trước.',
    );
    if (!ok || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.deleteCategory(category.id),
      successMessage: 'Đã xoá danh mục.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('DANH MỤC')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.clay500,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          if (provider.isLoading && provider.categories.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (provider.categories.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.sell_outlined,
                title: 'Chưa có danh mục nào',
                subtitle: 'Sản phẩm bắt buộc phải thuộc một danh mục, nên hãy tạo danh mục trước.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchCategories(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sand200),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                            ),
                            AdminStatusChip(
                              category.statusText,
                              tone: category.status.toUpperCase() == RecordStatusX.active ? 1 : 2,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '/${category.slug}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              color: AppColors.clay600,
                              onPressed: () => _openForm(category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 19),
                              color: Colors.red.shade600,
                              onPressed: () => _delete(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchCategories(page: p),
          ),
        ],
      ),
    );
  }
}
