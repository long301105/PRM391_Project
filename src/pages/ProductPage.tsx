import { ArrowLeft } from "lucide-react";
import { Link, useLocation, useNavigate, useOutletContext, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { ProductDetail } from "@/components/ProductDetail";
import { fetchProductBySlug } from "@/api/catalog";
import { useCatalog } from "@/context/CatalogContext";
import { ApiError } from "@/lib/api";
import type { Product } from "@/data/products";
import { CATALOG_LABEL, paths, productCatalogSlug } from "@/lib/paths";
import type { ShopOutletContext } from "@/context/ShopOutlet";

export function ProductPage() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { openCart, openCheckout, openSizeGuide } = useOutletContext<ShopOutletContext>();
  const { findBySlug, cacheProduct, loading: catalogLoading } = useCatalog();

  const cached = slug ? findBySlug(slug) : undefined;
  const [detail, setDetail] = useState<Product | null>(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    if (!slug) return;
    let alive = true;

    setNotFound(false);
    setLoadingDetail(true);
    fetchProductBySlug(slug)
      .then((full) => {
        if (!alive) return;
        setDetail(full);
        cacheProduct(full);
      })
      .catch((err) => {
        if (!alive) return;
        if (err instanceof ApiError && err.status === 404) setNotFound(true);
      })
      .finally(() => {
        if (alive) setLoadingDetail(false);
      });

    return () => {
      alive = false;
    };
  }, [slug, cacheProduct]);

  const product = detail ?? cached;
  const from = (location.state as { from?: string } | null)?.from;

  if (!product && (loadingDetail || catalogLoading) && !notFound) {
    return (
      <div className="flex min-h-[70vh] items-center justify-center px-6 pt-24 pb-20">
        <p className="text-sm text-mute">Đang tải sản phẩm...</p>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center px-6 pt-24 pb-20 text-center">
        <p className="text-[11px] font-bold uppercase tracking-[0.25em] text-clay-500">404</p>
        <h1 className="mt-2 font-display text-3xl font-bold text-ink">Không tìm thấy sản phẩm</h1>
        <p className="mt-2 max-w-sm text-sm text-mute">
          Mẫu này không còn trên showroom hoặc đường dẫn không đúng.
        </p>
        <Link
          to={paths.catalog("all")}
          className="mt-6 inline-flex items-center gap-1.5 rounded-full bg-ink px-6 py-3 text-xs font-bold uppercase tracking-wider text-white"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          Về cửa hàng
        </Link>
      </div>
    );
  }

  const category = productCatalogSlug(product);
  const backTo = from?.startsWith("/bo-suu-tap") ? from : paths.catalog(category);

  return (
    <ProductDetail
      key={product.id}
      product={product}
      crumbs={[
        { label: "Trang chủ", to: paths.home },
        { label: CATALOG_LABEL[category], to: paths.catalog(category) },
        { label: product.name },
      ]}
      onClose={() => navigate(backTo)}
      onOpenCart={openCart}
      onOpenCheckout={openCheckout}
      onOpenSizeGuide={openSizeGuide}
      onOpenRelated={(p) =>
        navigate(paths.product(p.slug), {
          state: { from: backTo },
        })
      }
    />
  );
}
