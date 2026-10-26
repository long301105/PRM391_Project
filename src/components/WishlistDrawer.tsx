"use client";

import { motion } from "framer-motion";
import { ArrowRight, Heart, Trash2, X } from "lucide-react";
import { useEffect, useMemo } from "react";
import { useCatalog } from "@/context/CatalogContext";
import type { Product } from "@/data/products";
import { useCart } from "@/context/CartContext";
import { formatMoney } from "@/lib/format";

interface WishlistDrawerProps {
  onClose: () => void;
  onOpenProduct: (p: Product) => void;
}

export function WishlistDrawer({ onClose, onOpenProduct }: WishlistDrawerProps) {
  const { wishlist, toggleWishlist } = useCart();
  const { products } = useCatalog();

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const items = useMemo(() => {
    return products.filter((p) => wishlist.includes(p.id));
  }, [wishlist]);

  return (
    <motion.div
      className="fixed inset-0 z-[3000]"
      initial="hidden"
      animate="show"
      exit="exit"
    >
      <motion.div
        variants={{ hidden: { opacity: 0 }, show: { opacity: 1 }, exit: { opacity: 0 } }}
        transition={{ duration: 0.25 }}
        onClick={onClose}
        className="absolute inset-0 bg-ink/55 backdrop-blur-sm"
      />
      <motion.aside
        variants={{ hidden: { x: "100%" }, show: { x: 0 }, exit: { x: "100%" } }}
        transition={{ type: "tween", ease: [0.22, 1, 0.36, 1], duration: 0.38 }}
        className="absolute right-0 top-0 flex h-[100dvh] w-full max-w-[400px] flex-col bg-sand-50 shadow-2xl"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-sand-200 px-5 py-4">
          <h2 className="flex items-center gap-2 font-display text-lg font-semibold text-ink">
            Sản phẩm yêu thích
            {wishlist.length > 0 && (
              <span className="rounded-full bg-clay-500 px-2 py-0.5 text-xs font-bold text-white">
                {wishlist.length}
              </span>
            )}
          </h2>
          <button
            onClick={onClose}
            aria-label="Đóng"
            className="flex h-9 w-9 items-center justify-center rounded-full text-mute transition hover:bg-sand-200 hover:text-ink"
          >
            <X className="h-5 w-5" strokeWidth={1.8} />
          </button>
        </div>

        {/* Content */}
        {items.length === 0 ? (
          <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
            <span className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-sand-200 text-mute">
              <Heart className="h-8 w-8" strokeWidth={1.4} />
            </span>
            <p className="font-display text-xl text-ink font-semibold">Chưa có sản phẩm yêu thích</p>
            <p className="mt-1 text-xs text-mute max-w-xs leading-relaxed">
              Nhấn vào biểu tượng trái tim ở các mẫu thiết kế để lưu lại ngắm sau nhé nàng.
            </p>
            <button
              onClick={onClose}
              className="mt-6 rounded-full bg-ink px-6 py-3 text-xs font-semibold uppercase tracking-wider text-white shadow transition hover:bg-clay-600"
            >
              Xem bộ sưu tập
            </button>
          </div>
        ) : (
          <div className="soft-scroll flex-1 overflow-y-auto px-5 divide-y divide-sand-200">
            {items.map((item) => (
              <div key={item.id} className="flex items-center gap-3.5 py-4">
                <img
                  src={item.img}
                  alt={item.name}
                  className="h-20 w-16 shrink-0 rounded-xl object-cover ring-1 ring-sand-200"
                />
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-semibold text-ink truncate">{item.name}</h4>
                  <p className="mt-1 text-sm font-bold text-clay-600">
                    {formatMoney(item.price)}
                  </p>
                  <div className="mt-2 flex gap-2">
                    <button
                      onClick={() => onOpenProduct(item)}
                      className="flex items-center gap-1 text-xs font-semibold text-ink underline hover:text-clay-600"
                    >
                      <span>Xem ngay</span>
                      <ArrowRight className="h-3 w-3" />
                    </button>
                    <span className="text-mute">·</span>
                    <button
                      onClick={() => toggleWishlist(item.id)}
                      className="text-xs text-mute hover:text-rose-600"
                    >
                      Bỏ thích
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </motion.aside>
    </motion.div>
  );
}
