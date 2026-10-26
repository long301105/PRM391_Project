"use client";

import { AnimatePresence, motion, useAnimationControls } from "framer-motion";
import {
  ChevronLeft,
  ChevronRight,
  Heart,
  Minus,
  Plus,
  RefreshCw,
  Ruler,
  ShoppingBag,
  Sparkles,
  Star,
  Truck,
  X,
  Zap,
} from "lucide-react";
import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { GALLERY_EXTRA, SIZES } from "@/data/products";
import { useCatalog } from "@/context/CatalogContext";
import type { Product } from "@/data/products";
import { useCart, type CartItem } from "@/context/CartContext";
import { IconToast, useToast } from "@/context/ToastContext";
import { formatMoney } from "@/lib/format";
import { Breadcrumb, type Crumb } from "@/components/Breadcrumb";
import { ReviewsBoard } from "@/components/ReviewsBoard";
import { cn } from "@/utils/cn";

interface ProductDetailProps {
  product: Product;
  crumbs: Crumb[];
  onClose: () => void;
  onOpenCart: () => void;
  onOpenCheckout: (directItems?: CartItem[]) => void;
  onOpenSizeGuide: () => void;
  onOpenRelated: (p: Product) => void;
}

const FEATURES = [
  { icon: Sparkles, text: "Thiết kế độc quyền La Boutique Sunset" },
  { icon: Truck, text: "Freeship toàn quốc khi thanh toán bằng QR" },
  { icon: RefreshCw, text: "Đổi trả tận tâm trong vòng 7 ngày" },
];

export function ProductDetail({
  product,
  crumbs,
  onClose,
  onOpenCart,
  onOpenCheckout,
  onOpenSizeGuide,
  onOpenRelated,
}: ProductDetailProps) {
  const { addItem, addMultipleItems, count, isWished, toggleWishlist } = useCart();
  const { products } = useCatalog();
  const { showToast } = useToast();
  const wished = isWished(product.id);

  const gallery = useMemo(() => {
    if (product.gallery && product.gallery.length > 0) {
      return product.gallery;
    }
    return [product.img, ...GALLERY_EXTRA];
  }, [product]);

  const related = useMemo(() => {
    const same = products.filter((p) => p.id !== product.id && p.type === product.type);
    const others = products.filter((p) => p.id !== product.id && p.type !== product.type);
    return [...same, ...others].slice(0, 10);
  }, [product]);

  const [imgIndex, setImgIndex] = useState(0);
  const [selection, setSelection] = useState<Record<string, number>>({});
  const [error, setError] = useState(false);
  const [mobilePicker, setMobilePicker] = useState(false);
  const [pendingAction, setPendingAction] = useState<"add" | "buy" | null>(null);
  const controls = useAnimationControls();
  const relatedRef = useRef<HTMLDivElement>(null);
  const relatedLoop = useMemo(
    () => (related.length ? [...related, ...related, ...related] : []),
    [related]
  );

  const relatedStep = () => {
    const el = relatedRef.current;
    const card = el?.querySelector<HTMLElement>("[data-related-card]");
    if (!el || !card) return 192;
    const styles = window.getComputedStyle(el);
    const gap = parseFloat(styles.columnGap || styles.gap || "16") || 16;
    return card.offsetWidth + gap;
  };

  const keepRelatedInfinite = () => {
    const el = relatedRef.current;
    if (!el || related.length === 0) return;
    const setW = relatedStep() * related.length;
    if (setW <= 0) return;
    if (el.scrollLeft < setW * 0.5) el.scrollLeft += setW;
    else if (el.scrollLeft >= setW * 2.5) el.scrollLeft -= setW;
  };

  const scrollRelated = (dir: -1 | 1) => {
    const el = relatedRef.current;
    if (!el || related.length === 0) return;
    keepRelatedInfinite();
    el.scrollBy({ left: dir * relatedStep(), behavior: "smooth" });
    window.setTimeout(keepRelatedInfinite, 450);
  };

  useLayoutEffect(() => {
    const el = relatedRef.current;
    if (!el || related.length === 0) return;
    el.scrollLeft = relatedStep() * related.length;
  }, [product.id, related.length]);

  useEffect(() => {
    const el = relatedRef.current;
    if (!el) return;
    let timer = 0;
    const onScroll = () => {
      window.clearTimeout(timer);
      timer = window.setTimeout(keepRelatedInfinite, 60);
    };
    el.addEventListener("scroll", onScroll, { passive: true });
    el.addEventListener("scrollend", keepRelatedInfinite);
    return () => {
      window.clearTimeout(timer);
      el.removeEventListener("scroll", onScroll);
      el.removeEventListener("scrollend", keepRelatedInfinite);
    };
  }, [related.length]);

  // Reset state on product switch
  useEffect(() => {
    setImgIndex(0);
    setSelection({});
    setError(false);
    setMobilePicker(false);
    setPendingAction(null);
  }, [product]);

  // Keyboard escape
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const toDirectItems = (sel: Record<string, number>): CartItem[] =>
    Object.entries(sel)
      .filter(([, qty]) => qty > 0)
      .map(([size, qty]) => ({
        id: product.id,
        name: product.name,
        price: product.price,
        img: product.img,
        size,
        qty,
      }));

  const toggleSize = (s: string) => {
    setError(false);
    setSelection((prev) => {
      const next = { ...prev };
      if (next[s]) {
        delete next[s];
      } else {
        next[s] = 1;
      }
      return next;
    });
  };

  const changeQty = (s: string, delta: number) => {
    setSelection((prev) => ({
      ...prev,
      [s]: Math.max(1, (prev[s] ?? 1) + delta),
    }));
  };

  const totalQty = Object.values(selection).reduce((a, b) => a + b, 0);
  const total = product.price * totalQty;
  const displayTotal = totalQty > 0 ? total : product.price;
  const hasSelection = Object.keys(selection).length > 0;

  // Add to cart logic
  const handleAddToCart = () => {
    if (!hasSelection) {
      setError(true);
      controls.start({ x: [0, -8, 8, -6, 6, 0], transition: { duration: 0.35 } });
      return;
    }
    addMultipleItems(product, selection);
    showToast("Đã thêm vào giỏ", "success", "cart");
    setSelection({});
    setError(false);
    setMobilePicker(false);
    setPendingAction(null);
  };

  const handleBuyNow = () => {
    if (!hasSelection) {
      setError(true);
      controls.start({ x: [0, -8, 8, -6, 6, 0], transition: { duration: 0.35 } });
      return;
    }
    const items = toDirectItems(selection);
    setSelection({});
    setError(false);
    setMobilePicker(false);
    setPendingAction(null);
    onOpenCheckout(items);
  };

  const handleMobileAdd = () => {
    if (!hasSelection) {
      setPendingAction("add");
      setMobilePicker(true);
      setError(false);
      return;
    }
    handleAddToCart();
  };

  const handleMobileBuyNow = () => {
    if (!hasSelection) {
      setPendingAction("buy");
      setMobilePicker(true);
      setError(false);
      return;
    }
    handleBuyNow();
  };

  const applyQuickSize = (s: string) => {
    if (pendingAction === "add") {
      addItem(product, s, 1);
      showToast("Đã thêm vào giỏ", "success", "cart");
      setSelection({});
      setMobilePicker(false);
      setPendingAction(null);
      setError(false);
      return;
    }
    if (pendingAction === "buy") {
      setSelection({});
      setMobilePicker(false);
      setPendingAction(null);
      setError(false);
      onOpenCheckout([
        {
          id: product.id,
          name: product.name,
          price: product.price,
          img: product.img,
          size: s,
          qty: 1,
        },
      ]);
      return;
    }
    toggleSize(s);
    setMobilePicker(false);
  };

  const nextImg = () => setImgIndex((i) => (i + 1) % gallery.length);
  const prevImg = () => setImgIndex((i) => (i - 1 + gallery.length) % gallery.length);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.25 }}
      className="fixed inset-0 z-[2000] bg-sand-50"
    >
      <div className="flex h-full flex-col">
        {/* Top Navbar */}
        <div className="z-10 flex h-16 shrink-0 items-center justify-between border-b border-sand-200 bg-sand-50/95 px-4 backdrop-blur-md sm:px-6">
          <button
            onClick={onClose}
            className="flex items-center gap-1.5 text-[13px] font-bold uppercase tracking-wider text-ink transition hover:text-clay-600 active:scale-95"
          >
            <ChevronLeft className="h-4 w-4" strokeWidth={2.2} />
            <span>Quay lại</span>
          </button>
          <span className="font-display text-sm font-bold tracking-[0.2em] text-ink">
            LA BOUTIQUE <span className="text-clay-500">VN</span>
          </span>
          <div className="flex items-center">
            <button
              onClick={() => {
                toggleWishlist(product.id);
                if (!wished) showToast("Đã thêm yêu thích", "success", "wishlist");
              }}
              aria-label={wished ? "Bỏ yêu thích" : "Thêm yêu thích"}
              className="relative flex h-10 w-10 items-center justify-center rounded-full transition hover:bg-sand-200"
            >
              <Heart
                className="h-5 w-5"
                strokeWidth={1.8}
                fill={wished ? "currentColor" : "none"}
              />
              <IconToast anchor="wishlist" />
            </button>
            <button
              onClick={onOpenCart}
              aria-label="Giỏ hàng"
              className="relative flex h-10 w-10 items-center justify-center rounded-full transition hover:bg-sand-200"
            >
              <ShoppingBag className="h-5 w-5" strokeWidth={1.8} />
              {count > 0 && (
                <span className="absolute -right-0.5 -top-0.5 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-clay-500 px-1 text-[10px] font-bold text-white">
                  {count}
                </span>
              )}
              <IconToast anchor="cart" />
            </button>
          </div>
        </div>

        {/* Scrollable Body */}
        <div className="soft-scroll flex-1 overflow-y-auto">
          <div className="mx-auto max-w-6xl px-4 py-4 sm:px-6 lg:py-8">
            <Breadcrumb items={crumbs} className="mb-4 sm:mb-5" />
            <div className="grid gap-8 lg:grid-cols-2 lg:gap-14 items-start">
              {/* Photo Gallery with snug fit */}
              <div>
                <div className="flex gap-3.5 items-start">
                  {/* Thumbnails desktop with max-height matching main image aspect ratio */}
                  {gallery.length > 1 && (
                    <div className="hidden sm:flex flex-col gap-2.5 max-h-[500px] overflow-y-auto no-scrollbar soft-scroll pr-1 shrink-0">
                      {gallery.map((src, i) => (
                        <button
                          key={i}
                          onClick={() => setImgIndex(i)}
                          className={cn(
                            "h-[76px] w-[60px] shrink-0 overflow-hidden rounded-xl ring-2 transition-all",
                            i === imgIndex
                              ? "ring-clay-500 shadow-md scale-105"
                              : "ring-sand-200 opacity-70 hover:opacity-100"
                          )}
                        >
                          <img
                            src={src}
                            alt={`${product.name} ${i + 1}`}
                            className="h-full w-full object-cover"
                          />
                        </button>
                      ))}
                    </div>
                  )}

                  {/* Main image - perfect aspect-[3/4] fit */}
                  <div className="relative flex-1 aspect-[3/4] overflow-hidden rounded-3xl bg-sand-200 shadow-md">
                    <AnimatePresence mode="wait">
                      <motion.img
                        key={imgIndex}
                        src={gallery[imgIndex]}
                        alt={product.name}
                        initial={{ opacity: 0, scale: 1.02 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.25 }}
                        className="h-full w-full object-cover object-center"
                      />
                    </AnimatePresence>

                    {gallery.length > 1 && (
                      <>
                        <button
                          onClick={prevImg}
                          aria-label="Ảnh trước"
                          className="absolute left-3 top-1/2 -translate-y-1/2 flex h-9 w-9 items-center justify-center rounded-full bg-white/85 text-ink shadow backdrop-blur transition hover:bg-white"
                        >
                          <ChevronLeft className="h-4 w-4" />
                        </button>
                        <button
                          onClick={nextImg}
                          aria-label="Ảnh sau"
                          className="absolute right-3 top-1/2 -translate-y-1/2 flex h-9 w-9 items-center justify-center rounded-full bg-white/85 text-ink shadow backdrop-blur transition hover:bg-white"
                        >
                          <ChevronRight className="h-4 w-4" />
                        </button>
                      </>
                    )}

                    {product.tag && (
                      <span className="absolute left-4 top-4 rounded-full bg-clay-500 px-3 py-1 text-xs font-bold uppercase tracking-wider text-white shadow-md">
                        {product.tag}
                      </span>
                    )}
                  </div>
                </div>

                {/* Thumbnails mobile */}
                {gallery.length > 1 && (
                  <div className="no-scrollbar mt-3 flex gap-2.5 overflow-x-auto sm:hidden pb-1">
                    {gallery.map((src, i) => (
                      <button
                        key={i}
                        onClick={() => setImgIndex(i)}
                        className={cn(
                          "h-[68px] w-[54px] shrink-0 overflow-hidden rounded-xl ring-2 transition-all",
                          i === imgIndex ? "ring-clay-500 scale-105 shadow-sm" : "ring-sand-200 opacity-70"
                        )}
                      >
                        <img
                          src={src}
                          alt={`${product.name} ${i + 1}`}
                          className="h-full w-full object-cover"
                        />
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Product Info & Multi-size Picker */}
              <div className="lg:pt-0">
                <p className="text-[11px] font-bold uppercase tracking-[0.25em] text-clay-500">
                  {product.isSummer ? "La Boutique Sunset Collection" : "LA Boutique VN"}
                </p>

                <h1 className="mt-1.5 font-display text-3xl font-bold leading-tight text-ink sm:text-4xl">
                  {product.name}
                </h1>

                <div className="mt-2.5 flex items-center gap-2">
                  <div className="flex text-amber-500">
                    {[0, 1, 2, 3, 4].map((i) => (
                      <Star key={i} className="h-4 w-4" fill="currentColor" strokeWidth={0} />
                    ))}
                  </div>
                  <span className="text-sm font-medium text-mute">4.9 · 128 đánh giá</span>
                </div>

                {/* Price display */}
                <div className="mt-4 flex items-baseline gap-3">
                  <span className="font-display text-3xl font-bold tabular-nums text-clay-600 sm:text-4xl">
                    {formatMoney(product.price)}
                  </span>
                  {product.originalPrice && product.originalPrice > product.price && (
                    <span className="text-sm text-mute line-through">
                      {formatMoney(product.originalPrice)}
                    </span>
                  )}
                </div>

                <p className="mt-3.5 text-sm leading-relaxed text-mute">
                  {product.description ||
                    "Mảnh ghép hoàn hảo cho những ngày rực rỡ bên biển. Thiết kế mang tinh thần tự do của La Boutique Sunset — chất liệu tơ tằm mềm mịn kết hợp linen organic thoáng mát, form dáng tôn vóc chuẩn chỉnh."}
                </p>

                <hr className="my-5 border-sand-200" />

                {/* MULTI-SIZE PICKER */}
                <motion.div animate={controls}>
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-bold text-ink">
                      Kích cỡ (Có thể chọn nhiều size)
                      {totalQty > 0 && (
                        <span className="ml-1 font-normal text-clay-600">· {totalQty} món</span>
                      )}
                    </span>
                    <button
                      onClick={onOpenSizeGuide}
                      className="flex items-center gap-1 text-xs font-semibold text-clay-600 underline-offset-2 hover:underline"
                    >
                      <Ruler className="h-4 w-4" strokeWidth={1.8} />
                      Bảng size gợi ý
                    </button>
                  </div>

                  {/* Size chips */}
                  <div className="mt-2.5 flex flex-wrap gap-3">
                    {SIZES.map((s) => (
                      <button
                        key={s}
                        onClick={() => toggleSize(s)}
                        className={cn(
                          "flex h-12 min-w-12 items-center justify-center rounded-2xl border px-5 text-sm font-bold transition active:scale-95",
                          selection[s]
                            ? "border-ink bg-ink text-white shadow-md scale-105"
                            : "border-sand-300 bg-white text-ink hover:border-ink hover:bg-sand-100"
                        )}
                      >
                        Size {s}
                        {selection[s] && (
                          <span className="ml-1.5 rounded-full bg-clay-500 px-1.5 py-0.2 text-[10px] text-white">
                            x{selection[s]}
                          </span>
                        )}
                      </button>
                    ))}
                  </div>

                  {/* Multi-size Quantity rows */}
                  <AnimatePresence initial={false}>
                    {hasSelection && (
                      <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: "auto" }}
                        exit={{ opacity: 0, height: 0 }}
                        className="overflow-hidden"
                      >
                        <div className="mt-3.5 space-y-2 rounded-2xl bg-sand-100/70 p-3.5 border border-sand-200">
                          <p className="text-[11px] uppercase font-bold text-mute">
                            Số lượng theo từng kích cỡ đã chọn:
                          </p>
                          <AnimatePresence initial={false}>
                            {SIZES.filter((s) => selection[s]).map((s) => (
                              <motion.div
                                key={s}
                                layout
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                exit={{ opacity: 0, x: 10 }}
                                className="flex items-center justify-between rounded-xl border border-sand-200 bg-white px-3.5 py-2 shadow-sm"
                              >
                                <div className="flex items-center gap-2">
                                  <span className="font-bold text-sm text-ink">Size {s}</span>
                                  <span className="text-xs text-mute">
                                    ({formatMoney(product.price * selection[s])})
                                  </span>
                                </div>

                                <div className="flex items-center gap-2">
                                  <div className="flex items-center rounded-full border border-sand-300 bg-sand-50">
                                    <button
                                      onClick={() => changeQty(s, -1)}
                                      disabled={selection[s] <= 1}
                                      aria-label={`Giảm size ${s}`}
                                      className="flex h-8 w-8 items-center justify-center text-ink transition hover:text-clay-600 disabled:opacity-30"
                                    >
                                      <Minus className="h-3.5 w-3.5" strokeWidth={2} />
                                    </button>
                                    <span className="w-7 text-center text-xs font-bold tabular-nums text-ink">
                                      {selection[s]}
                                    </span>
                                    <button
                                      onClick={() => changeQty(s, 1)}
                                      aria-label={`Tăng size ${s}`}
                                      className="flex h-8 w-8 items-center justify-center text-ink transition hover:text-clay-600"
                                    >
                                      <Plus className="h-3.5 w-3.5" strokeWidth={2} />
                                    </button>
                                  </div>
                                  <button
                                    onClick={() => toggleSize(s)}
                                    aria-label={`Bỏ size ${s}`}
                                    className="p-1 text-mute transition hover:text-rose-600"
                                  >
                                    <X className="h-4 w-4" strokeWidth={2} />
                                  </button>
                                </div>
                              </motion.div>
                            ))}
                          </AnimatePresence>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                  {error && (
                    <motion.p
                      initial={{ opacity: 0, y: -4 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="mt-2 text-xs font-semibold text-rose-600"
                    >
                      * Nàng vui lòng chọn ít nhất một kích cỡ (Size S, M hoặc L) nhé.
                    </motion.p>
                  )}
                </motion.div>

                {/* Desktop Action Buttons (Thêm vào giỏ & Mua ngay) */}
                <div className="mt-7 hidden gap-3 lg:grid lg:grid-cols-2">
                  <button
                    onClick={handleAddToCart}
                    className="flex h-14 items-center justify-center gap-2 rounded-full border-2 border-ink bg-white text-xs font-bold uppercase tracking-wider text-ink shadow-sm transition hover:bg-ink hover:text-white active:scale-98"
                  >
                    <ShoppingBag className="h-4 w-4" strokeWidth={2} />
                    <span>Thêm vào giỏ {totalQty > 0 && `(${totalQty})`}</span>
                  </button>

                  <button
                    onClick={handleBuyNow}
                    className="flex h-14 items-center justify-center gap-2 rounded-full bg-clay-500 text-xs font-bold uppercase tracking-wider text-white shadow-lg shadow-clay-600/30 transition hover:bg-clay-600 active:scale-98"
                  >
                    <Zap className="h-4 w-4 fill-white" />
                    <span>Mua ngay {totalQty > 0 ? `· ${formatMoney(total)}` : ""}</span>
                  </button>
                </div>

                {/* Boutique Guarantees Strip */}
                <div className="mt-6 space-y-2.5 rounded-2xl bg-white p-4 ring-1 ring-sand-200/80">
                  {FEATURES.map(({ icon: Icon, text }) => (
                    <div key={text} className="flex items-center gap-3 text-xs text-mute">
                      <span className="flex h-7 w-7 items-center justify-center rounded-full bg-clay-50 text-clay-600">
                        <Icon className="h-3.5 w-3.5" strokeWidth={2} />
                      </span>
                      <span>{text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Related Products Section */}
            <section className="mt-16 border-t border-sand-200 pt-10">
              <div className="mb-6 flex items-end justify-between gap-4">
                <div>
                  <h3 className="font-display text-2xl font-bold text-ink sm:text-3xl">
                    Gợi ý phối đồ mùa hè
                  </h3>
                  <p className="mt-0.5 text-xs text-mute">
                    Những mảnh ghép kết hợp cùng {product.name} cho vẻ ngoài hoàn hảo
                  </p>
                </div>
                <div className="hidden shrink-0 items-center gap-2 md:flex">
                  <button
                    type="button"
                    aria-label="Gợi ý trước"
                    onClick={() => scrollRelated(-1)}
                    className="flex h-10 w-10 items-center justify-center rounded-full border border-sand-300 bg-white text-ink shadow-sm transition hover:border-ink hover:bg-ink hover:text-white active:scale-95"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    aria-label="Gợi ý tiếp"
                    onClick={() => scrollRelated(1)}
                    className="flex h-10 w-10 items-center justify-center rounded-full border border-sand-300 bg-white text-ink shadow-sm transition hover:border-ink hover:bg-ink hover:text-white active:scale-95"
                  >
                    <ChevronRight className="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div ref={relatedRef} className="no-scrollbar flex gap-4 overflow-x-auto pb-4">
                {relatedLoop.map((p, i) => (
                  <div
                    key={`${p.id}-${i}`}
                    data-related-card
                    onClick={() => onOpenRelated(p)}
                    className="group w-44 shrink-0 cursor-pointer"
                  >
                    <div className="relative aspect-[3/4] overflow-hidden rounded-2xl bg-sand-200 ring-1 ring-sand-200">
                      <img
                        src={p.img}
                        alt={p.name}
                        className="h-full w-full object-cover transition duration-300 group-hover:scale-105"
                      />
                      <div className="absolute inset-0 bg-ink/20 opacity-0 transition group-hover:opacity-100 flex items-center justify-center">
                        <span className="rounded-full bg-white px-3 py-1 text-[10px] font-bold uppercase text-ink shadow">
                          Xem chi tiết
                        </span>
                      </div>
                    </div>
                    <p className="mt-2 line-clamp-1 text-xs font-semibold text-ink transition-colors group-hover:text-clay-600">
                      {p.name}
                    </p>
                    <p className="text-xs font-bold tabular-nums text-clay-600">
                      {formatMoney(p.price)}
                    </p>
                  </div>
                ))}
              </div>
            </section>

            {/* Reviews Board */}
            <ReviewsBoard productId={product.id} />
          </div>

          <div className="h-32 lg:hidden" />
        </div>

        {/* Mobile Sticky Bottom Bar */}
        <div
          className="shrink-0 border-t border-sand-200 bg-sand-50/95 backdrop-blur-md lg:hidden"
          style={{ paddingBottom: "calc(env(safe-area-inset-bottom) + 0.75rem)" }}
        >
          {/* Quick size drawer on mobile */}
          <AnimatePresence initial={false}>
            {mobilePicker && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
                className="overflow-hidden px-4"
              >
                <div className="border-b border-sand-200 py-3">
                  <div className="mb-2 flex items-center justify-between">
                    <span className="text-xs font-bold uppercase text-ink">
                      {pendingAction === "buy" ? "Chọn size — mua ngay" : "Chọn size — thêm vào giỏ"}
                    </span>
                    <button
                      onClick={() => {
                        setMobilePicker(false);
                        setPendingAction(null);
                      }}
                      aria-label="Đóng"
                      className="flex h-7 w-7 items-center justify-center rounded-full text-mute hover:bg-sand-200"
                    >
                      <X className="h-4 w-4" strokeWidth={2} />
                    </button>
                  </div>
                  <div className="flex gap-2">
                    {SIZES.map((s) => (
                      <button
                        key={s}
                        onClick={() => applyQuickSize(s)}
                        className={cn(
                          "flex-1 rounded-xl border py-2.5 text-xs font-bold uppercase transition",
                          selection[s]
                            ? "border-ink bg-ink text-white"
                            : "border-sand-300 bg-white text-ink hover:border-ink"
                        )}
                      >
                        Size {s}
                      </button>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          <div className="flex items-center justify-between gap-3 px-4 pt-3">
            <div className="min-w-0">
              <p className="text-[10px] uppercase font-bold tracking-wider text-mute truncate">
                {totalQty > 0 ? `Tạm tính (${totalQty} món)` : "Tạm tính"}
              </p>
              <p className="text-base font-bold tabular-nums text-clay-600 truncate">
                {formatMoney(displayTotal)}
              </p>
            </div>

            <div className="flex flex-1 gap-2">
              <button
                onClick={handleMobileAdd}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-full border border-ink bg-white py-3 text-xs font-bold uppercase tracking-wider text-ink transition active:scale-95"
              >
                <ShoppingBag className="h-4 w-4" strokeWidth={1.8} />
                <span>Thêm</span>
              </button>

              <button
                onClick={handleMobileBuyNow}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-clay-500 py-3 text-xs font-bold uppercase tracking-wider text-white shadow-md transition active:scale-95"
              >
                <Zap className="h-4 w-4 fill-white" />
                <span>Mua ngay</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
