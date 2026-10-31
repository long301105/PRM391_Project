import { ChevronLeft, ChevronRight, PackageOpen } from "lucide-react";
import { useEffect, useLayoutEffect, useMemo, useState } from "react";
import { Navigate, useLocation, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { FilterSidebar } from "@/components/FilterBar";
import { fetchProducts, type CollectionItem } from "@/api/catalog";
import type { CollectionPublicSummaryResponse } from "@/api/types";
import { api, type PageResponse } from "@/lib/api";
import { ProductCard } from "@/components/ProductCard";
import { PRICE_MAX, PRICE_MIN } from "@/data/products";
import { useCatalog } from "@/context/CatalogContext";
import type { Product } from "@/data/products";
import { Breadcrumb } from "@/components/Breadcrumb";
import { CATALOG_LABEL, isCatalogSlug, paths } from "@/lib/paths";
import { jumpToId } from "@/lib/scroll";
import { cn } from "@/utils/cn";

const ITEMS_PER_PAGE = 8;

const CAT_LABEL: Record<string, string> = {
  all: "Toàn bộ sản phẩm",
  sunset: "La Boutique VN Sunset Collection",
  ao: "Áo, Đầm & Cổ Yếm Nữ",
  quan: "Quần & Chân Váy Nữ",
};

export function CatalogPage() {
  const { products, loading, error, reload } = useCatalog();
  const { category: catParam } = useParams();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [search, setSearch] = useState("");
  const [price, setPrice] = useState({ min: PRICE_MIN, max: PRICE_MAX });
  const [sort, setSort] = useState("featured");

  const invalidCategory = !!catParam && !isCatalogSlug(catParam);
  const requestedSlug = searchParams.get("bst") || (catParam === "sunset" ? "sunset" : null);
  const [publicCollections, setPublicCollections] = useState<CollectionItem[]>([]);
  const [collectionsReady, setCollectionsReady] = useState(false);
  const [collectionProducts, setCollectionProducts] = useState<Product[]>([]);
  const [collectionLoading, setCollectionLoading] = useState(false);
  const [collectionError, setCollectionError] = useState<string | null>(null);
  const [collectionProductsRetry, setCollectionProductsRetry] = useState(0);
  const selectedCollection = publicCollections.find((c) => c.slug === requestedSlug);
  const category = requestedSlug ? `collection:${requestedSlug}` :
    catParam && isCatalogSlug(catParam) ? catParam : "all";
  const sourceProducts = requestedSlug ? collectionProducts : products;
  const currentPage = Math.max(1, parseInt(searchParams.get("trang") || "1", 10) || 1);

  useEffect(() => {
    let alive = true;
    let pending = false;
    const refresh = async () => {
      if (pending || document.visibilityState === "hidden") return;
      pending = true;
      try {
        let page = 0;
        let totalPages = 1;
        const all: CollectionItem[] = [];
        do {
          const result = await api.get<PageResponse<CollectionPublicSummaryResponse>>("/collections", {
            page, size: 100, sort: "createdAt,desc",
          });
          if (!Array.isArray(result.content) || typeof result.totalPages !== "number") {
            throw new Error("Invalid collection page");
          }
          all.push(...result.content.map((item) => ({
            id: item.id, name: item.collectionName, slug: item.slug,
            coverImageUrl: item.coverImageUrl ?? undefined,
          })));
          totalPages = result.totalPages;
          page++;
        } while (page < totalPages);
        if (alive) {
          setPublicCollections(all);
          setCollectionsReady(true);
        }
      } catch {
        // A network failure is not evidence that a collection is hidden.
      } finally {
        pending = false;
      }
    };
    const onVisibility = () => { if (document.visibilityState === "visible") void refresh(); };
    void refresh();
    const timer = window.setInterval(() => void refresh(), 15000);
    document.addEventListener("visibilitychange", onVisibility);
    return () => { alive = false; window.clearInterval(timer); document.removeEventListener("visibilitychange", onVisibility); };
  }, []);

  useEffect(() => {
    if (requestedSlug && collectionsReady && !selectedCollection) {
      navigate(paths.catalog("all"), { replace: true });
      void reload();
    }
  }, [requestedSlug, collectionsReady, selectedCollection, navigate, reload]);

  useEffect(() => {
    if (!requestedSlug || !selectedCollection) {
      setCollectionProducts([]);
      setCollectionError(null);
      setCollectionLoading(false);
      return;
    }
    let alive = true;
    setCollectionProducts([]);
    setCollectionLoading(true);
    setCollectionError(null);
    const loadCollectionProducts = async () => {
      try {
        let page = 0;
        let totalPages = 1;
        const all: Product[] = [];
        do {
          const result = await fetchProducts({ collection: requestedSlug, page, size: 100, sort: "createdAt,desc" });
          all.push(...result.items);
          totalPages = result.totalPages;
          page++;
        } while (page < totalPages);
        if (alive) setCollectionProducts(all);
      } catch {
        if (alive) setCollectionError("Không tải được sản phẩm của bộ sưu tập.");
      } finally {
        if (alive) setCollectionLoading(false);
      }
    };
    void loadCollectionProducts();
    return () => { alive = false; };
  }, [requestedSlug, selectedCollection?.id, collectionProductsRetry]);

  const categoryOptions = [
    { id: "all", label: "Tất cả", fullLabel: "Tất cả sản phẩm" },
    ...publicCollections.map((c) => ({ id: `collection:${c.slug}`, label: c.name, fullLabel: c.name })),
    { id: "ao", label: "Áo & Đầm", fullLabel: "Áo, Đầm & Cổ Yếm" },
    { id: "quan", label: "Quần & Váy", fullLabel: "Quần & Chân Váy" },
  ];

  const openProduct = (p: Product) => {
    navigate(paths.product(p.slug), { state: { from: location.pathname + location.search } });
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return sourceProducts.filter((p) => {
      const matchName =
        p.name.toLowerCase().includes(q) ||
        (p.description && p.description.toLowerCase().includes(q));
      const matchPrice = p.price >= price.min && p.price <= price.max;
      return matchName && matchPrice;
    });
  }, [search, price, sourceProducts]);

  const sortedFiltered = useMemo(() => {
    const arr = [...filtered];
    if (sort === "price-asc") arr.sort((a, b) => a.price - b.price);
    else if (sort === "price-desc") arr.sort((a, b) => b.price - a.price);
    else if (sort === "new") {
      arr.sort((a, b) => (b.createdAt ?? "").localeCompare(a.createdAt ?? ""));
    }
    return arr;
  }, [filtered, sort]);

  const catFiltered = useMemo(() => {
    if (category === "all" || requestedSlug) return sortedFiltered;
    return sortedFiltered.filter((p) => p.type === category);
  }, [sortedFiltered, category, requestedSlug]);

  const categoryCounts = useMemo(() => {
    return {
      all: sortedFiltered.length,
      ao: sortedFiltered.filter((p) => p.type === "ao").length,
      quan: sortedFiltered.filter((p) => p.type === "quan").length,
    };
  }, [sortedFiltered]);

  const totalPages = Math.max(1, Math.ceil(catFiltered.length / ITEMS_PER_PAGE));
  const safePage = Math.min(currentPage, totalPages);
  const paginatedItems = useMemo(() => {
    const start = (safePage - 1) * ITEMS_PER_PAGE;
    return catFiltered.slice(start, start + ITEMS_PER_PAGE);
  }, [catFiltered, safePage]);

  const goPage = (page: number) => {
    const next = new URLSearchParams(searchParams);
    if (page <= 1) next.delete("trang");
    else next.set("trang", String(page));
    setSearchParams(next, { replace: false });
  };

  const resetPageParam = () => {
    if (!searchParams.has("trang")) return;
    const next = new URLSearchParams(searchParams);
    next.delete("trang");
    setSearchParams(next, { replace: true });
  };

  useLayoutEffect(() => {
    if (invalidCategory) return;
    jumpToId("catalog-top");
  }, [safePage, category, invalidCategory]);

  if (invalidCategory) {
    return <Navigate to={paths.catalog("all")} replace />;
  }

  return (
    <div className="relative isolate pt-20 sm:pt-24 pb-16 sm:pb-20 px-3 sm:px-6 max-w-7xl mx-auto" id="catalog-top">
      {selectedCollection?.coverImageUrl && (
        <div aria-hidden="true" className="pointer-events-none absolute -z-10 top-0 left-1/2 h-[360px] w-screen -translate-x-1/2 overflow-hidden">
          <img src={selectedCollection.coverImageUrl} alt="" className="h-full w-full scale-110 object-cover blur-md" />
          <div className="absolute inset-0 bg-gradient-to-b from-sand-50/50 via-sand-50/65 to-sand-50" />
        </div>
      )}
      <div className="mb-4 sm:mb-6 flex flex-wrap items-center justify-between gap-2.5 border-b border-sand-200 pb-3 sm:pb-4">
        <div>
          <Breadcrumb
            className="mb-2"
            items={[
              { label: "Trang chủ", to: paths.home },
              { label: "Bộ sưu tập", to: paths.catalog("all") },
              ...(category !== "all" ? [{ label: selectedCollection?.name || CATALOG_LABEL[category] || CAT_LABEL[category] }] : []),
            ]}
          />
          <h1 className="font-display text-2xl sm:text-3xl md:text-4xl font-bold text-ink">
            {selectedCollection?.name || CAT_LABEL[category] || "Khám phá toàn bộ sản phẩm"}
          </h1>
          <p className="mt-0.5 text-xs text-mute">
            Hiển thị <strong className="text-ink font-bold">{catFiltered.length}</strong> sản phẩm trong danh mục
          </p>
        </div>
      </div>

      <div className="flex gap-2.5 sm:gap-4 lg:gap-8 items-start">
        <FilterSidebar
          categoryOptions={categoryOptions}
          category={category}
          onCategory={(cat: string) => {
            if (cat.startsWith("collection:")) {
              navigate(`${paths.catalog("all")}?bst=${encodeURIComponent(cat.substring("collection:".length))}`);
            } else navigate(paths.catalog(cat));
          }}
          search={search}
          onSearch={(s: string) => {
            setSearch(s);
            resetPageParam();
          }}
          price={price}
          onPrice={(p) => {
            setPrice(p);
            resetPageParam();
          }}
          sort={sort}
          onSort={setSort}
          resultCount={catFiltered.length}
          onOpenProduct={openProduct}
          categoryCounts={categoryCounts}
        />

        <div className="flex-1 min-w-0">
          {(requestedSlug ? (!collectionsReady || collectionLoading) : (loading && products.length === 0)) ? (
            <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-sand-300 bg-white py-16 text-center text-mute">
              <p className="text-sm font-medium text-ink">Đang tải sản phẩm...</p>
            </div>
          ) : (requestedSlug ? collectionError : (error && products.length === 0 ? error : null)) ? (
            <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-rose-300 bg-white py-16 text-center">
              <PackageOpen className="mb-2.5 h-9 w-9 text-rose-300" strokeWidth={1.3} />
              <p className="text-sm font-medium text-ink">Không tải được sản phẩm</p>
              <p className="mt-1 max-w-sm px-6 text-xs leading-relaxed text-mute">{requestedSlug ? collectionError : error}</p>
              <button
                type="button"
                onClick={() => {
                  if (requestedSlug && collectionError) {
                    setCollectionProductsRetry((value) => value + 1);
                  } else {
                    void reload();
                  }
                }}
                className="mt-4 rounded-full bg-ink px-6 py-2.5 text-[11px] font-bold uppercase tracking-wider text-white"
              >
                Thử lại
              </button>
            </div>
          ) : paginatedItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-sand-300 py-16 text-center text-mute bg-white">
              <PackageOpen className="mb-2.5 h-9 w-9 text-sand-300" strokeWidth={1.3} />
              <p className="text-sm font-medium text-ink">Không tìm thấy sản phẩm phù hợp</p>
              <p className="mt-1 text-xs text-mute">Vui lòng điều chỉnh khoảng giá hoặc chọn danh mục khác</p>
            </div>
          ) : (
              <div className="grid grid-cols-2 md:grid-cols-3 gap-2.5 sm:gap-4 md:gap-5">
              {paginatedItems.map((p, i) => (
                <ProductCard key={p.id} product={p} index={i} onOpen={openProduct} />
              ))}
            </div>
          )}

          {totalPages > 1 && (
            <div className="mt-8 sm:mt-12 flex items-center justify-center gap-1.5 sm:gap-2">
              <button
                onClick={() => goPage(safePage - 1)}
                disabled={safePage === 1}
                className="flex h-8 sm:h-9 items-center gap-1 rounded-full border border-sand-300 bg-white px-2.5 sm:px-3 text-[10px] sm:text-xs font-bold text-ink shadow-xs transition hover:border-ink disabled:opacity-40 disabled:hover:border-sand-300"
              >
                <ChevronLeft className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Trang trước</span>
              </button>

              <div className="flex items-center gap-1 sm:gap-1.5 px-1">
                {Array.from({ length: totalPages }).map((_, idx) => {
                  const pageNum = idx + 1;
                  const isCurrent = pageNum === safePage;
                  return (
                    <button
                      key={pageNum}
                      onClick={() => goPage(pageNum)}
                      className={cn(
                        "flex h-7 w-7 sm:h-8 sm:w-8 items-center justify-center rounded-full text-[11px] sm:text-xs font-bold transition",
                        isCurrent
                          ? "bg-clay-500 text-white shadow-xs"
                          : "bg-white text-ink border border-sand-200 hover:border-sand-300"
                      )}
                    >
                      {pageNum}
                    </button>
                  );
                })}
              </div>

              <button
                onClick={() => goPage(safePage + 1)}
                disabled={safePage === totalPages}
                className="flex h-8 sm:h-9 items-center gap-1 rounded-full border border-sand-300 bg-white px-2.5 sm:px-3 text-[10px] sm:text-xs font-bold text-ink shadow-xs transition hover:border-ink disabled:opacity-40 disabled:hover:border-sand-300"
              >
                <span className="hidden sm:inline">Trang sau</span>
                <ChevronRight className="h-3.5 w-3.5" />
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
