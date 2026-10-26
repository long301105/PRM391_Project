
export type RecordStatus = "ACTIVE" | "HIDDEN" | "DELETED";
export type ProductSize = "S" | "M" | "L";
export type OrderStatusApi = "PENDING" | "CONFIRMED" | "SHIPPING" | "COMPLETED" | "CANCELLED";
export type PaymentMethodApi = "COD" | "BANK_TRANSFER";
export type AccountStatusApi = "ACTIVE" | "DISABLED" | "LOCKED";

export interface ProductResponse {
  id: string;
  name: string;
  slug: string;
  sku: string;
  price: number;
  originalPrice: number | null;
  tag: string | null;
  thumbnail: string | null;
  isSummer: boolean | null;
  isFeatured: boolean | null;
  status: RecordStatus;
  categoryId: string | null;
  categoryName: string | null;
  categorySlug: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ProductImageResponse {
  id: string;
  imageUrl: string;
  sortOrder: number | null;
}

export interface ProductVariantResponse {
  id: string;
  size: ProductSize;
  stockQuantity: number;
  version: number;
}

export interface ProductDetailResponse extends ProductResponse {
  description: string | null;
  material: string | null;
  careInstructions: string | null;
  gallery: ProductImageResponse[];
  variants: ProductVariantResponse[];
}

export interface CategoryPublicResponse {
  id: string;
  categoryName: string;
  slug: string;
}

export interface CategoryResponse extends CategoryPublicResponse {
  status: RecordStatus;
  createdAt: string;
  updatedAt: string;
}

export interface CollectionPublicSummaryResponse {
  id: string;
  collectionName: string;
  slug: string;
  coverImageUrl: string | null;
}

export interface CollectionPublicProductResponse {
  productId: string;
  productName: string;
  productSlug: string | null;
  thumbnail: string | null;
  price: number;
  originalPrice: number | null;
  tag: string | null;
}

export interface CollectionPublicDetailResponse extends CollectionPublicSummaryResponse {
  products: {
    content: CollectionPublicProductResponse[];
    page: number;
    size: number;
    totalElements: number;
    totalPages: number;
    first: boolean;
    last: boolean;
  };
}

export interface CollectionProductResponse {
  productId: string;
  productName: string;
  productSlug: string | null;
  thumbnail: string | null;
  status: RecordStatus;
  sortOrder: number | null;
}

export interface CollectionSummaryResponse extends CollectionPublicSummaryResponse {
  status: RecordStatus;
  version: number;
  createdAt: string;
  updatedAt: string;
}

export interface CollectionDetailResponse extends CollectionSummaryResponse {
  products: CollectionProductResponse[];
  visibleProductCount: number;
}

export interface OrderItemResponse {
  id: string;
  productId: string;
  productName: string;
  productSlug: string | null;
  imageUrl: string | null;
  size: ProductSize;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
}

export interface OrderResponse {
  id: string;
  orderNumber: string;
  accountId: string;
  status: OrderStatusApi;
  paymentMethod: PaymentMethodApi;
  receiverName: string;
  phone: string;
  email: string | null;
  address: string;
  note: string | null;
  cancelReason: string | null;
  subtotal: number;
  shippingFee: number;
  discount: number;
  total: number;
  items: OrderItemResponse[];
  createdAt: string;
  updatedAt: string;
}

export interface OrderSummaryResponse {
  id: string;
  orderNumber: string;
  status: OrderStatusApi;
  paymentMethod: PaymentMethodApi;
  receiverName: string;
  total: number;
  totalItems: number;
  createdAt: string;
}

export interface OrderItemRequest {
  productId: string;
  size: ProductSize;
  quantity: number;
}

export interface CreateOrderRequest {
  receiverName: string;
  phone: string;
  email?: string;
  address: string;
  note?: string;
  paymentMethod: PaymentMethodApi;
  items: OrderItemRequest[];
}

export interface AccountResponse {
  id: string;
  email: string;
  roleId: string | null;
  roleName: string | null;
  status: AccountStatusApi;
  provider: "LOCAL" | "GOOGLE";
  hasPassword: boolean;
  lockedUntil: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface RoleResponse {
  id: string;
  roleName: string;
  description: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface LoginResponse {
  accessToken: string | null;
  refreshToken: string | null;
  email?: string;
  roleName?: string;
}
