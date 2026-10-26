"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import {
  fetchCategories,
  fetchCollections,
  fetchProducts,
  type CategoryItem,
  type CollectionItem,
} from "@/api/catalog";
import type { Product } from "@/data/products";
import { ApiError } from "@/lib/api";

interface CatalogContextValue {
  products: Product[];
  categories: CategoryItem[];
  collections: CollectionItem[];
  loading: boolean;
  error: string | null;
  reload: () => Promise<void>;
  findBySlug: (slug: string) => Product | undefined;
  findById: (id: string) => Product | undefined;
  cacheProduct: (product: Product) => void;
}

const CatalogContext = createContext<CatalogContextValue | null>(null);

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [collections, setCollections] = useState<CollectionItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [productPage, categoryList, collectionList] = await Promise.all([
        fetchProducts({ size: 100, sort: "createdAt,desc" }),
        fetchCategories().catch(() => [] as CategoryItem[]),
        fetchCollections().catch(() => [] as CollectionItem[]),
      ]);

      setProducts(productPage.items);
      setCategories(categoryList);
      setCollections(collectionList);
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : "Không tải được danh sách sản phẩm. Vui lòng thử lại."
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const cacheProduct = useCallback((product: Product) => {
    setProducts((prev) => {
      const index = prev.findIndex((p) => p.id === product.id);
      if (index < 0) return [...prev, product];
      const next = [...prev];
      next[index] = { ...next[index], ...product };
      return next;
    });
  }, []);

  const value = useMemo<CatalogContextValue>(
    () => ({
      products,
      categories,
      collections,
      loading,
      error,
      reload,
      findBySlug: (slug: string) => products.find((p) => p.slug === slug),
      findById: (id: string) => products.find((p) => p.id === id),
      cacheProduct,
    }),
    [products, categories, collections, loading, error, reload, cacheProduct]
  );

  return <CatalogContext.Provider value={value}>{children}</CatalogContext.Provider>;
}

export function useCatalog() {
  const ctx = useContext(CatalogContext);
  if (!ctx) throw new Error("useCatalog must be used within CatalogProvider");
  return ctx;
}
