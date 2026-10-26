import type { CartItem, OrderRecord } from "@/context/CartContext";
import type { Category, CollectionType, Product } from "@/data/products";
import type {
  CollectionPublicProductResponse,
  OrderResponse,
  OrderStatusApi,
  PaymentMethodApi,
  ProductDetailResponse,
  ProductResponse,
} from "./types";

const PLACEHOLDER_IMAGE = "/images/products/sunset-main-1.jpg";

function toCategory(categorySlug: string | null): Category {
  return categorySlug === "quan" ? "quan" : "ao";
}

function toCollection(isSummer: boolean | null): CollectionType {
  return isSummer ? "sunset" : "regular";
}

export function mapProduct(dto: ProductResponse | ProductDetailResponse): Product {
  const detail = dto as Partial<ProductDetailResponse>;
  const galleryUrls = (detail.gallery ?? [])
    .slice()
    .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
    .map((image) => image.imageUrl)
    .filter(Boolean);

  const img = dto.thumbnail || galleryUrls[0] || PLACEHOLDER_IMAGE;

  return {
    id: dto.id,
    name: dto.name,
    slug: dto.slug,
    price: dto.price,
    originalPrice: dto.originalPrice ?? undefined,
    type: toCategory(dto.categorySlug),
    isSummer: dto.isSummer ?? false,
    isFeatured: dto.isFeatured ?? false,
    collection: toCollection(dto.isSummer),
    img,
    gallery: galleryUrls.length > 0 ? galleryUrls : [img],
    tag: dto.tag ?? undefined,
    description: detail.description ?? undefined,
    material: detail.material ?? undefined,
    careInstructions: detail.careInstructions ?? undefined,
    createdAt: dto.createdAt,
    variants: detail.variants?.map((v) => ({ size: v.size, stockQuantity: v.stockQuantity })),
  };
}

export function mapCollectionProduct(dto: CollectionPublicProductResponse): Product {
  const img = dto.thumbnail || PLACEHOLDER_IMAGE;
  return {
    id: dto.productId,
    name: dto.productName,
    slug: dto.productSlug ?? "",
    price: dto.price,
    originalPrice: dto.originalPrice ?? undefined,
    type: "ao",
    isSummer: true,
    collection: "sunset",
    img,
    gallery: [img],
    tag: dto.tag ?? undefined,
  };
}

const STATUS_MAP: Record<OrderStatusApi, OrderRecord["status"]> = {
  PENDING: "pending",
  CONFIRMED: "confirmed",
  SHIPPING: "shipping",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
};

export function toApiPaymentMethod(payment: OrderRecord["paymentMethod"]): PaymentMethodApi {
  return payment === "qr" ? "BANK_TRANSFER" : "COD";
}

export function fromApiPaymentMethod(payment: PaymentMethodApi): OrderRecord["paymentMethod"] {
  return payment === "BANK_TRANSFER" ? "qr" : "cod";
}

export function mapOrder(dto: OrderResponse): OrderRecord {
  const items: CartItem[] = dto.items.map((item) => ({
    id: item.productId,
    name: item.productName,
    price: item.unitPrice,
    img: item.imageUrl || PLACEHOLDER_IMAGE,
    size: item.size,
    qty: item.quantity,
  }));

  return {
    orderNumber: dto.orderNumber,
    customerName: dto.receiverName,
    phone: dto.phone,
    email: dto.email ?? undefined,
    address: dto.address,
    note: dto.note ?? undefined,
    paymentMethod: fromApiPaymentMethod(dto.paymentMethod),
    status: STATUS_MAP[dto.status] ?? "pending",
    subtotal: dto.subtotal,
    shippingFee: dto.shippingFee,
    discount: dto.discount,
    total: dto.total,
    items,
    createdAt: dto.createdAt,
    cancelReason: dto.cancelReason ?? undefined,
  };
}
