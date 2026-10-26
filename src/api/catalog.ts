import { api, type PageResponse } from "@/lib/api";
import type { Product } from "@/data/products";
import { mapCollectionProduct, mapProduct } from "./mappers";
import type {
  CategoryPublicResponse,
  CollectionPublicDetailResponse,
  CollectionPublicSummaryResponse,
  ProductDetailResponse,
  ProductResponse,
} from "./types";

export interface ProductQuery {
  category?: string;
  collection?: string;
  search?: string;
  minPrice?: number;
  maxPrice?: number;
  featured?: boolean;
  page?: number;
  size?: number;
  sort?: string;
}

export async function fetchProducts(query: ProductQuery = {}): Promise<{
  items: Product[];
  totalElements: number;
  totalPages: number;
  page: number;
}> {
  const result = await api.get<PageResponse<ProductResponse>>("/products", {
    category: query.category,
    collection: query.collection,
    search: query.search,
    minPrice: query.minPrice,
    maxPrice: query.maxPrice,
    featured: query.featured,
    page: query.page ?? 0,
    size: Math.min(query.size ?? 100, 100),
    sort: query.sort ?? "createdAt,desc",
  });

  return {
    items: result.content.map(mapProduct),
    totalElements: result.totalElements,
    totalPages: result.totalPages,
    page: result.page,
  };
}

export async function fetchProductBySlug(slug: string): Promise<Product> {
  const result = await api.get<ProductDetailResponse>(`/products/slug/${encodeURIComponent(slug)}`);
  return mapProduct(result);
}

export async function fetchProductById(id: string): Promise<Product> {
  const result = await api.get<ProductDetailResponse>(`/products/id/${encodeURIComponent(id)}`);
  return mapProduct(result);
}

export interface CategoryItem {
  id: string;
  name: string;
  slug: string;
}

export async function fetchCategories(): Promise<CategoryItem[]> {
  const result = await api.get<PageResponse<CategoryPublicResponse>>("/categories", {
    page: 0,
    size: 100,
    sort: "createdAt,desc",
  });
  return result.content.map((dto) => ({ id: dto.id, name: dto.categoryName, slug: dto.slug }));
}

export interface CollectionItem {
  id: string;
  name: string;
  slug: string;
  coverImageUrl?: string;
}

export async function fetchCollections(): Promise<CollectionItem[]> {
  const result = await api.get<PageResponse<CollectionPublicSummaryResponse>>("/collections", {
    page: 0,
    size: 50,
    sort: "createdAt,desc",
  });
  return result.content.map((dto) => ({
    id: dto.id,
    name: dto.collectionName,
    slug: dto.slug,
    coverImageUrl: dto.coverImageUrl ?? undefined,
  }));
}

export async function fetchCollectionBySlug(
  slug: string,
  page = 0,
  size = 50
): Promise<CollectionItem & { products: Product[]; totalProducts: number }> {
  const result = await api.get<CollectionPublicDetailResponse>(
    `/collections/slug/${encodeURIComponent(slug)}`,
    { page, size }
  );

  return {
    id: result.id,
    name: result.collectionName,
    slug: result.slug,
    coverImageUrl: result.coverImageUrl ?? undefined,
    products: result.products.content.map(mapCollectionProduct),
    totalProducts: result.products.totalElements,
  };
}
