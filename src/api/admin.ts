import { api, type PageResponse } from "@/lib/api";
import type {
  AccountResponse,
  AccountStatusApi,
  CategoryResponse,
  CollectionDetailResponse,
  CollectionSummaryResponse,
  OrderResponse,
  OrderStatusApi,
  OrderSummaryResponse,
  ProductDetailResponse,
  ProductResponse,
  ProductSize,
  ProductVariantResponse,
  RecordStatus,
  RoleResponse,
} from "./types";

export interface PageQuery {
  page?: number;
  size?: number;
  sort?: string;
}

function pageParams(query: PageQuery = {}, defaultSort = "createdAt,desc") {
  return {
    page: query.page ?? 0,
    size: Math.min(query.size ?? 20, 100),
    sort: query.sort ?? defaultSort,
  };
}

export const adminAccounts = {
  list: (query?: PageQuery) =>
    api.get<PageResponse<AccountResponse>>("/accounts", pageParams(query)),

  get: (id: string) => api.get<AccountResponse>(`/accounts/${id}`),

  create: (body: { email: string; password: string; roleId: string }) =>
    api.post<AccountResponse>("/accounts", body),

  update: (id: string, body: { email?: string; roleId?: string }) =>
    api.patch<AccountResponse>(`/accounts/${id}`, body),

  updateStatus: (id: string, body: { status: AccountStatusApi; lockedUntil?: string }) =>
    api.patch<AccountResponse>(`/accounts/${id}/status`, body),

  remove: (id: string) => api.del<void>(`/accounts/${id}`),
};

export const adminRoles = {
  list: (query?: PageQuery) =>
    api.get<PageResponse<RoleResponse>>("/roles", pageParams(query, "roleName,asc")),

  get: (id: string) => api.get<RoleResponse>(`/roles/${id}`),

  create: (body: { roleName: string; description?: string }) =>
    api.post<RoleResponse>("/roles", body),

  update: (id: string, body: { roleName?: string; description?: string }) =>
    api.patch<RoleResponse>(`/roles/${id}`, body),

  remove: (id: string) => api.del<void>(`/roles/${id}`),
};

export const adminCategories = {
  list: (query?: PageQuery) =>
    api.get<PageResponse<CategoryResponse>>("/categories/admin", pageParams(query)),

  get: (id: string) => api.get<CategoryResponse>(`/categories/admin/${id}`),

  create: (body: { categoryName: string; slug?: string }) =>
    api.post<CategoryResponse>("/categories/admin", body),

  update: (id: string, body: { categoryName?: string; slug?: string; status?: RecordStatus }) =>
    api.patch<CategoryResponse>(`/categories/admin/${id}`, body),

  remove: (id: string) => api.del<void>(`/categories/admin/${id}`),
};

export interface ProductWriteBody {
  name?: string;
  slug?: string;
  sku?: string;
  price?: number;
  originalPrice?: number | null;
  description?: string;
  material?: string;
  careInstructions?: string;
  tag?: string;
  thumbnail?: string;
  isSummer?: boolean;
  isFeatured?: boolean;
  status?: RecordStatus;
  categoryId?: string;
}

export const adminProducts = {
  list: (query?: PageQuery) =>
    api.get<PageResponse<ProductResponse>>("/products/admin", pageParams(query)),

  get: (id: string) => api.get<ProductDetailResponse>(`/products/admin/${id}`),

  create: (body: ProductWriteBody) => api.post<ProductDetailResponse>("/products/admin", body),

  update: (id: string, body: ProductWriteBody) =>
    api.patch<ProductDetailResponse>(`/products/admin/${id}`, body),

  remove: (id: string) => api.del<void>(`/products/admin/${id}`),

  addImage: (id: string, file: File) =>
    api.upload<ProductDetailResponse>("POST", `/products/admin/${id}/images`, file),

  replaceImage: (id: string, imageId: string, file: File) =>
    api.upload<ProductDetailResponse>("PUT", `/products/admin/${id}/images/${imageId}`, file),

  removeImage: (id: string, imageId: string) =>
    api.del<ProductDetailResponse>(`/products/admin/${id}/images/${imageId}`),

  uploadThumbnail: (id: string, file: File) =>
    api.upload<ProductDetailResponse>("PUT", `/products/admin/${id}/thumbnail`, file),

  selectThumbnail: (id: string, imageId: string) =>
    api.patch<ProductDetailResponse>(`/products/admin/${id}/thumbnail`, { imageId }),

  listVariants: (id: string) =>
    api.get<ProductVariantResponse[]>(`/products/admin/${id}/variants`),

  addVariant: (id: string, body: { size: ProductSize; stockQuantity: number }) =>
    api.post<ProductDetailResponse>(`/products/admin/${id}/variants`, body),

  updateVariant: (
    id: string,
    variantId: string,
    body: { stockQuantity: number; expectedVersion: number }
  ) => api.patch<ProductDetailResponse>(`/products/admin/${id}/variants/${variantId}`, body),

  removeVariant: (id: string, variantId: string) =>
    api.del<ProductDetailResponse>(`/products/admin/${id}/variants/${variantId}`),
};

export const adminCollections = {
  list: (query?: PageQuery) =>
    api.get<PageResponse<CollectionSummaryResponse>>("/collections/admin", pageParams(query)),

  get: (id: string) => api.get<CollectionDetailResponse>(`/collections/admin/${id}`),

  create: (body: {
    collectionName: string;
    slug?: string;
    coverImageUrl?: string;
    productIds: string[];
  }) => api.post<CollectionDetailResponse>("/collections/admin", body),

  update: (
    id: string,
    body: {
      expectedVersion: number;
      collectionName?: string;
      slug?: string;
      coverImageUrl?: string;
      clearCoverImage?: boolean;
    }
  ) => api.patch<CollectionDetailResponse>(`/collections/admin/${id}`, body),

  replaceProducts: (id: string, body: { expectedVersion: number; productIds: string[] }) =>
    api.put<CollectionDetailResponse>(`/collections/admin/${id}/products`, body),

  uploadCover: (id: string, file: File) =>
    api.upload<CollectionDetailResponse>("PUT", `/collections/admin/${id}/cover`, file),

  publish: (id: string, expectedVersion: number) =>
    api.patch<CollectionDetailResponse>(`/collections/admin/${id}/publish`, { expectedVersion }),

  hide: (id: string, expectedVersion: number) =>
    api.patch<CollectionDetailResponse>(`/collections/admin/${id}/hide`, { expectedVersion }),

  remove: (id: string, expectedVersion: number) =>
    api.del<void>(`/collections/admin/${id}`, { expectedVersion }),
};

export const ALLOWED_ORDER_TRANSITIONS: Record<OrderStatusApi, OrderStatusApi[]> = {
  PENDING: ["CONFIRMED", "CANCELLED"],
  CONFIRMED: ["SHIPPING", "CANCELLED"],
  SHIPPING: ["COMPLETED"],
  COMPLETED: [],
  CANCELLED: [],
};

export const ORDER_STATUS_LABEL: Record<OrderStatusApi, string> = {
  PENDING: "Chờ xác nhận",
  CONFIRMED: "Đã xác nhận",
  SHIPPING: "Đang giao",
  COMPLETED: "Hoàn thành",
  CANCELLED: "Đã huỷ",
};

export const adminOrders = {
  list: (query?: PageQuery & { status?: OrderStatusApi }) =>
    api.get<PageResponse<OrderSummaryResponse>>("/orders", {
      ...pageParams(query),
      status: query?.status,
    }),

  get: (id: string) => api.get<OrderResponse>(`/orders/${id}`),

  getByNumber: (orderNumber: string) =>
    api.get<OrderResponse>(`/orders/number/${encodeURIComponent(orderNumber.toUpperCase())}`),

  updateStatus: (id: string, status: OrderStatusApi) =>
    api.patch<OrderResponse>(`/orders/${id}/status`, { status }),
};
