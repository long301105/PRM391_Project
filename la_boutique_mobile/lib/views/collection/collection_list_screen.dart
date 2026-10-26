import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../providers/collection_provider.dart';
import 'collection_detail_screen.dart';

class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key});

  @override
  State<CollectionListScreen> createState() => _CollectionListScreenState();
}

class _CollectionListScreenState extends State<CollectionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().fetchCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('BỘ SƯU TẬP')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchCollections(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(CollectionProvider provider) {
    if (provider.isLoading && provider.collections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.collections.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.collections_bookmark_outlined, size: 56, color: AppColors.sand300),
          const SizedBox(height: 14),
          const Text(
            'Chưa có bộ sưu tập nào',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            provider.errorMessage ?? 'Shop đang chuẩn bị, nàng ghé lại sau nhé.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.collections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _CollectionCard(collection: provider.collections[index]),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionModel collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    final imagePath = Product.resolveImage(collection.coverImageUrl);
    final isNetwork = imagePath.startsWith('http');

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: collection)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: isNetwork
                  ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback())
                  : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback()),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.collectionName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Xem bộ sưu tập →',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.sand100,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.sand300, size: 32),
      );
}
