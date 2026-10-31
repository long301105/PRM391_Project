import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_screen.dart';
import '../admin/admin_home_screen.dart';
import '../admin/admin_conversations_screen.dart';
import '../collection/collection_list_screen.dart';
import '../map/store_map_screen.dart';
import '../notification/notification_screen.dart';
import '../product/product_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Lấy số thông báo chưa đọc cho chấm đỏ (nếu đã đăng nhập; chưa thì trả 0 im lặng).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  void _onExplorePressed() {
    setState(() => _currentIndex = 1); // Switch to Product Catalog tab
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();

    final tabs = [
      _HomeTab(onExplore: _onExplorePressed),
      ProductListScreen(isActive: _currentIndex == 1),
      const StoreMapScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.sand50,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.sand200.withValues(alpha: 0.8), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.clay500,
          unselectedItemColor: AppColors.mute.withValues(alpha: 0.7),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Sản phẩm',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Cửa hàng',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (notif.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.clay500,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback onExplore;

  const _HomeTab({required this.onExplore});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final PageController _heroController = PageController();
  int _currentHeroSlide = 0;
  Timer? _heroTimer;
  bool _nudgeDismissed = false; // tắt banner nhắc hoàn thiện hồ sơ trong phiên này

  final List<String> _heroSlides = [
    'assets/images/products/sunset-main-1.jpg',
    'assets/images/products/sunset-main-3.jpg',
    'assets/images/products/sunset-main-4.jpg',
    'assets/images/products/sunset-main-5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_heroController.hasClients) {
        final next = (_currentHeroSlide + 1) % _heroSlides.length;
        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final sunsetList = productProvider.sunsetCollection;
    final allProducts = productProvider.allProducts;

    // Nudge: đã đăng nhập nhưng hồ sơ chưa hoàn thiện (SĐT/địa chỉ...) → nhắc, không chặn.
    final user = context.watch<AuthProvider>().currentUser;
    final showProfileNudge = user != null && !user.profileCompleted && !_nudgeDismissed;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'LA BOUTIQUE',
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppColors.ink,
              ),
            ),
            const Text(
              'V I E T N A M',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w600,
                color: AppColors.clay600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Tư vấn trực tuyến',
            onPressed: () {
              // Admin bấm icon chat -> vào hộp thư hội thoại khách; khách thường -> chat với shop.
              final isAdmin =
                  (context.read<AuthProvider>().accountInfo?.roleName ?? '').toUpperCase() == 'ADMIN';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isAdmin ? const AdminConversationsScreen() : const ChatScreen(),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Giỏ hàng',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.clay500,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Nudge nhắc hoàn thiện hồ sơ (chỉ hiện khi profileCompleted == false)
            if (showProfileNudge)
              _ProfileNudgeCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                onDismiss: () => setState(() => _nudgeDismissed = true),
              ),

            // 1. Hero Auto Carousel (Editorial Luxury Style)
            SizedBox(
              height: 340,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _heroController,
                    itemCount: _heroSlides.length,
                    onPageChanged: (idx) => setState(() => _currentHeroSlide = idx),
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _heroSlides[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                  // Dark Vignette Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.darkVignette,
                      ),
                    ),
                  ),
                  // Hero Content Overlay
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tag Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 11),
                              SizedBox(width: 5),
                              Text(
                                'BỘ SƯU TẬP HÈ 2026 • SIGNATURE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LA BOUTIQUE SUNSET',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hành trình mùa hè của người nữ du mục — tự do & phóng khoáng cùng lụa tơ tằm & linen tự nhiên.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // CTA Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.clay500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 3,
                          ),
                          onPressed: widget.onExplore,
                          icon: const Text(
                            'KHÁM PHÁ BỘ SƯU TẬP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 0.6),
                          ),
                          label: const Icon(Icons.arrow_forward_rounded, size: 13),
                        ),
                        const SizedBox(height: 10),
                        // Carousel Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _heroSlides.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: _currentHeroSlide == i ? 16 : 5,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _currentHeroSlide == i ? AppColors.clay500 : Colors.white60,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Streamlined ValueStrip (Clean Modern Card)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8), width: 0.8),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: _ValueItem(
                          icon: Icons.local_shipping_outlined,
                          title: 'Freeship quét QR',
                          desc: 'Chuyển khoản QR miễn phí ship',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _ValueItem(
                          icon: Icons.cached_rounded,
                          title: 'Đổi trả 7 ngày',
                          desc: 'Hỗ trợ đổi size tận tâm',
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.6, color: AppColors.sand200),
                  ),
                  Row(
                    children: const [
                      Expanded(
                        child: _ValueItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Thanh toán linh hoạt',
                          desc: 'QR freeship hoặc COD tận tay',
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _ValueItem(
                          icon: Icons.support_agent_rounded,
                          title: 'Tư vấn chọn size 24/7',
                          desc: 'Stylist chuyên nghiệp chu đáo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if ((context.watch<AuthProvider>().accountInfo?.roleName ?? '').toUpperCase() ==
                'ADMIN')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.admin_panel_settings_outlined, size: 20, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Khu quản trị',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CollectionListScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.clay50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.clay100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.collections_bookmark_outlined, size: 20, color: AppColors.clay600),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tất cả bộ sưu tập',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.clay600),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Sunset Collection Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BST SUNSET SS26',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '3 Thiết kế biểu tượng phiên bản giới hạn',
                        style: TextStyle(fontSize: 11.5, color: AppColors.mute),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(initialCategory: 'sunset'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Row(
                      children: [
                        Text('Xem tất cả', style: TextStyle(color: AppColors.clay600, fontSize: 12, fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.clay600),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Sunset Items
            SizedBox(
              height: 285,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: sunsetList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 175,
                    child: ProductCard(
                      product: sunsetList[index],
                      heroPrefix: 'sunset',
                    ),
                  );
                },
              ),
            ),

            // 4. Brand Story Section (Editorial Luxury Banner)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.ink,
                image: const DecorationImage(
                  image: AssetImage('assets/images/products/sunset-main-4.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color(0x99000000), BlendMode.darken),
                ),
                boxShadow: AppColors.floatingShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.clay500.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CÂU CHUYỆN THƯƠNG HIỆU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tinh Thần La Boutique',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'LA BOUTIQUE VN sinh ra từ tình yêu với những bờ biển rực rỡ và ánh hoàng hôn ấm áp. Mỗi thiết kế là lời mời gọi nàng cất bước — tự do, bản năng và đầy khao khát khám phá những chân trời mới.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _StatItem(value: '10+', label: 'Thiết kế độc quyền'),
                      _StatItem(value: 'COD', label: 'Thanh toán tận tay'),
                      _StatItem(value: '7 Ngày', label: 'Hỗ trợ đổi size'),
                    ],
                  ),
                ],
              ),
            ),

            // 5. All Products Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TẤT CẢ THIẾT KẾ',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Đầy đủ các mẫu áo yếm, đầm lụa và chân váy mùa hè',
                        style: TextStyle(fontSize: 11.5, color: AppColors.mute),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grid of all products
            GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.57,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemCount: allProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: allProducts[index],
                  heroPrefix: 'all',
                );
              },
            ),

            // 6. Customer Reviews Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: AppColors.sand100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NÀNG THƠ CHIA SẺ',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Đánh giá chân thực từ khách hàng La Boutique',
                            style: TextStyle(fontSize: 11.5, color: AppColors.mute),
                          ),
                        ],
                      ),
                      const Icon(Icons.format_quote_rounded, color: AppColors.clay400, size: 28),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 135,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _ReviewCard(
                          name: 'Minh Anh',
                          rating: 5,
                          time: '2 tuần trước',
                          text: 'Váy lụa mặc đi biển quá đã, mát mẻ và lên form cực kỳ tôn dáng. Mình đã giới thiệu cho cả hội bạn!',
                        ),
                        SizedBox(width: 12),
                        _ReviewCard(
                          name: 'Khánh Linh',
                          rating: 5,
                          time: '1 tháng trước',
                          text: 'Chất linen thoáng mát, giặt máy nhiều lần vẫn giữ form. Màu sắc chuẩn y hình shop nhé.',
                        ),
                        SizedBox(width: 12),
                        _ReviewCard(
                          name: 'Thu Hà',
                          rating: 5,
                          time: '3 tuần trước',
                          text: 'Đầm đẹp, đường may chỉn chu. Giao hàng nhanh, đóng hộp sang xịn mịn như mua quà tặng.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileNudgeCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ProfileNudgeCard({required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.clay50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.clay100, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.clay100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: AppColors.clay600, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hồ sơ chưa hoàn thiện',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bổ sung SĐT & địa chỉ để đặt hàng nhanh hơn ✨',
                        style: TextStyle(fontSize: 10.5, color: AppColors.mute),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.clay500, size: 20),
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.mute),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _ValueItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.clay50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.clay500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 9.5, color: AppColors.mute),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppColors.clay300, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String time;
  final String text;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.time,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.clay100,
                    child: Text(
                      name[0],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.clay600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.ink)),
                ],
              ),
              Row(
                children: List.generate(
                  rating,
                  (index) => const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 9.5, color: AppColors.mute)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, height: 1.35, color: AppColors.ink),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
