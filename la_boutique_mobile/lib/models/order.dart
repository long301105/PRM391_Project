import 'cart_item.dart';
import 'product.dart';

class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String? productSlug;
  final String? imageUrl;
  final String size;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.imageUrl,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: (json['productName'] ?? '') as String,
      productSlug: json['productSlug'] as String?,
      imageUrl: json['imageUrl'] as String?,
      size: (json['size'] ?? 'M') as String,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productSlug': productSlug,
      'imageUrl': imageUrl,
      'size': size,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String phone;
  final String? email;
  final String address;
  final String? note;
  final List<CartItem> items;
  final List<OrderItemModel> orderItems;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final int totalItems;
  final String paymentMethod; // 'COD' or 'BANK_TRANSFER' (or 'BANKING')
  final String status; // 'PENDING', 'CONFIRMED', 'SHIPPING', 'COMPLETED', 'CANCELLED'

  final String? cancelReason;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    String? orderNumber,
    required this.customerName,
    required this.phone,
    this.email,
    required this.address,
    this.note,
    this.items = const [],
    this.orderItems = const [],
    required this.subtotal,
    this.discount = 0,
    this.shippingFee = 30000,
    required this.total,
    int? totalItems,
    required this.paymentMethod,
    this.status = 'PENDING',
    this.cancelReason,
    required this.createdAt,
  })  : orderNumber = orderNumber ?? id,
        totalItems = totalItems ?? (items.isNotEmpty ? items.length : orderItems.length);

  String get displayOrderNumber => orderNumber.isNotEmpty ? orderNumber : id;

  bool get canCustomerCancel => status.toUpperCase() == 'PENDING';

  String get statusText {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'CHỜ XÁC NHẬN':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
      case 'ĐÃ XÁC NHẬN':
      case 'ĐANG XỬ LÝ':
        return 'Đã xác nhận';
      case 'SHIPPING':
      case 'ĐANG GIAO HÀNG':
        return 'Đang giao hàng';
      case 'COMPLETED':
      case 'HOÀN THÀNH':
        return 'Hoàn thành';
      case 'CANCELLED':
      case 'ĐÃ HỦY':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get paymentMethodText {
    final p = paymentMethod.toUpperCase();
    if (p == 'COD') return 'Thanh toán COD';
    if (p == 'BANK_TRANSFER' || p == 'BANKING') return 'Chuyển khoản VietQR';
    return paymentMethod;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'items': items.map((e) => e.toJson()).toList(),
      'orderItems': orderItems.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'shippingFee': shippingFee,
      'total': total,
      'totalItems': totalItems,
      'paymentMethod': paymentMethod,
      'status': status,
      'cancelReason': cancelReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final oNum = (json['orderNumber'] ?? json['id'] ?? '') as String;
    final rName = (json['receiverName'] ?? json['customerName'] ?? '') as String;

    List<OrderItemModel> parsedOrderItems = [];
    List<CartItem> parsedCartItems = [];

    if (json['items'] is List) {
      for (var item in (json['items'] as List)) {
        if (item is Map<String, dynamic>) {
          if (item['product'] != null) {
            // Mobile CartItem format
            parsedCartItems.add(CartItem.fromJson(item));
          } else {
            // BE OrderItemResponse format
            final orderItem = OrderItemModel.fromJson(item);
            parsedOrderItems.add(orderItem);

            // Synthesize CartItem for backward UI compatibility
            parsedCartItems.add(CartItem(
              product: Product(
                id: orderItem.productId,
                name: orderItem.productName,
                slug: orderItem.productSlug ?? '',
                price: orderItem.unitPrice,
                type: 'ao',
                collection: 'REGULAR',
                img: orderItem.imageUrl ?? '',
                gallery: orderItem.imageUrl != null ? [orderItem.imageUrl!] : [],
              ),
              size: orderItem.size,
              quantity: orderItem.quantity,
            ));
          }
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse((json['createdAt'] ?? DateTime.now().toIso8601String()) as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return OrderModel(
      id: json['id']?.toString() ?? oNum,
      orderNumber: oNum,
      customerName: rName,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      address: (json['address'] ?? '') as String,
      note: json['note'] as String?,
      items: parsedCartItems,
      orderItems: parsedOrderItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 30000.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? parsedCartItems.length,
      paymentMethod: (json['paymentMethod'] ?? 'COD') as String,
      status: (json['status'] ?? 'PENDING') as String,
      cancelReason: json['cancelReason'] as String?,
      createdAt: parsedDate,
    );
  }
}
