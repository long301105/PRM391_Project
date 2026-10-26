"use client";

import { motion } from "framer-motion";
import { ArrowRight, Check, ExternalLink, Minus, Plus, ShoppingBag, Trash2, Truck, X } from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useCart, type CartItem } from "@/context/CartContext";
import { useToast } from "@/context/ToastContext";
import { CountUp } from "@/components/lightswind/count-up";
import { useCatalog } from "@/context/CatalogContext";
import { formatMoney } from "@/lib/format";
import { paths } from "@/lib/paths";
import { cn } from "@/utils/cn";

interface CartDrawerProps {
  onClose: () => void;
  onCheckout: (items: CartItem[]) => void;
}

const itemKey = (it: { id: string; size: string }) => `${it.id}-${it.size}`;

export function CartDrawer({ onClose, onCheckout }: CartDrawerProps) {
  const { items, count, updateQty, removeItem, removeMany } = useCart();
  const { products } = useCatalog();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const prevKeysRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    const current = items.map(itemKey);
    setSelected((prev) => {
      const next = new Set<string>();
      current.forEach((k) => {
        if (prev.has(k) || !prevKeysRef.current.has(k)) next.add(k);
      });
      return next;
    });
    prevKeysRef.current = new Set(current);
  }, [items]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const selectedItems = useMemo(
    () => items.filter((it) => selected.has(itemKey(it))),
    [items, selected]
  );
  const selectedCount = selectedItems.reduce((s, it) => s + it.qty, 0);
  const selectedSubtotal = selectedItems.reduce((s, it) => s + it.price * it.qty, 0);
  const allSelected = items.length > 0 && selected.size === items.length;

  const toggleOne = (key: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const toggleAll = () => {
    setSelected(allSelected ? new Set() : new Set(items.map(itemKey)));
  };

  const deleteSelected = () => {
    if (!selectedItems.length) {
      showToast("Chọn món cần xóa trước.", "info");
      return;
    }
    removeMany(selectedItems.map((it) => ({ id: it.id, size: it.size })));
  };

  const goCheckout = () => {
    if (!selectedItems.length) {
      showToast("Chọn ít nhất một món để thanh toán.", "info");
      return;
    }
    onCheckout(selectedItems);
  };

  const openProduct = (id: string) => {
    const slug = products.find((p) => p.id === id)?.slug;
    if (!slug) return;
    onClose();
    navigate(paths.product(slug), { state: { from: location.pathname + location.search } });
  };

  return (
    <motion.div className="fixed inset-0 z-[3000]" initial="hidden" animate="show" exit="exit">
      <motion.div
        variants={{ hidden: { opacity: 0 }, show: { opacity: 1 }, exit: { opacity: 0 } }}
        transition={{ duration: 0.25 }}
        onClick={onClose}
        className="absolute inset-0 bg-ink/55 backdrop-blur-sm"
      />
      <motion.aside
        variants={{ hidden: { x: "100%" }, show: { x: 0 }, exit: { x: "100%" } }}
        transition={{ type: "tween", ease: [0.22, 1, 0.36, 1], duration: 0.38 }}
        className="absolute right-0 top-0 flex h-[100dvh] w-full max-w-[420px] flex-col bg-sand-50 shadow-2xl"
      >
        <div className="flex items-center justify-between border-b border-sand-200 px-5 py-4">
          <h2 className="flex items-center gap-2 font-display text-lg font-semibold text-ink">
            Giỏ hàng của bạn
            {count > 0 && (
              <span className="rounded-full bg-clay-500 px-2 py-0.5 text-xs font-bold text-white">
                {count}
              </span>
            )}
          </h2>
          <button
            onClick={onClose}
            aria-label="Đóng giỏ hàng"
            className="flex h-9 w-9 items-center justify-center rounded-full text-mute transition hover:bg-sand-200 hover:text-ink"
          >
            <X className="h-5 w-5" strokeWidth={1.8} />
          </button>
        </div>

        <div className="flex items-center gap-2 border-b border-clay-200/50 bg-clay-100/70 px-5 py-2.5 text-xs text-clay-800">
          <Truck className="h-4 w-4 shrink-0 text-clay-600" />
          <span>Freeship toàn quốc khi thanh toán QR · COD +30.000đ</span>
        </div>

        {items.length === 0 ? (
          <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
            <span className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-sand-200 text-mute">
              <ShoppingBag className="h-8 w-8" strokeWidth={1.4} />
            </span>
            <p className="font-display text-xl font-semibold text-ink">Giỏ hàng đang trống</p>
            <p className="mt-1 max-w-xs text-xs leading-relaxed text-mute">
              Hãy thêm những thiết kế quyến rũ trong bộ sưu tập hè 2026 vào giỏ của bạn.
            </p>
            <button
              onClick={onClose}
              className="mt-6 rounded-full bg-ink px-6 py-3 text-xs font-semibold uppercase tracking-wider text-white shadow transition hover:bg-clay-600"
            >
              Khám phá sản phẩm
            </button>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between border-b border-sand-200 px-5 py-2.5">
              <button type="button" onClick={toggleAll} className="flex items-center gap-2 text-xs font-bold text-ink">
                <SelectMark checked={allSelected} />
                Chọn tất cả
              </button>
              <button
                type="button"
                onClick={deleteSelected}
                className="flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium text-mute transition hover:bg-rose-50 hover:text-rose-600"
              >
                <Trash2 className="h-3.5 w-3.5" strokeWidth={1.7} />
                Xóa đã chọn
              </button>
            </div>

            <div className="soft-scroll flex-1 divide-y divide-sand-200 overflow-y-auto px-5">
              {items.map((item) => {
                const key = itemKey(item);
                const checked = selected.has(key);
                return (
                  <div key={key} className="flex gap-3 py-4">
                    <button
                      type="button"
                      onClick={() => toggleOne(key)}
                      aria-label={checked ? "Bỏ chọn" : "Chọn thanh toán"}
                      className="mt-7 shrink-0"
                    >
                      <SelectMark checked={checked} />
                    </button>
                    <img
                      src={item.img}
                      alt={item.name}
                      className="h-24 w-[74px] shrink-0 rounded-xl object-cover ring-1 ring-sand-200"
                    />
                    <div className="flex flex-1 flex-col justify-between">
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <h4 className="line-clamp-2 text-sm font-semibold leading-snug text-ink">{item.name}</h4>
                          <button
                            onClick={() => removeItem(item.id, item.size)}
                            aria-label="Xóa sản phẩm"
                            className="shrink-0 p-1 text-mute transition hover:text-rose-600"
                          >
                            <Trash2 className="h-4 w-4" strokeWidth={1.7} />
                          </button>
                        </div>
                        <span className="mt-1 inline-block rounded border border-clay-200 bg-clay-50 px-2 py-0.5 text-[11px] font-semibold uppercase text-clay-700">
                          Size {item.size}
                        </span>
                        <button
                          type="button"
                          onClick={() => openProduct(item.id)}
                          className="mt-1.5 flex items-center gap-1 text-[11px] font-semibold text-clay-600 underline-offset-2 hover:underline"
                        >
                          <ExternalLink className="h-3 w-3" />
                          Xem sản phẩm
                        </button>
                      </div>

                      <div className="flex items-center justify-between pt-2">
                        <div className="flex items-center rounded-full border border-sand-300 bg-white">
                          <button
                            onClick={() => updateQty(item.id, item.size, item.qty - 1)}
                            disabled={item.qty <= 1}
                            aria-label="Giảm"
                            className="flex h-7 w-7 items-center justify-center text-ink transition hover:text-clay-600 disabled:opacity-30"
                          >
                            <Minus className="h-3 w-3" strokeWidth={2} />
                          </button>
                          <span className="w-7 text-center text-xs font-bold tabular-nums">{item.qty}</span>
                          <button
                            onClick={() => updateQty(item.id, item.size, item.qty + 1)}
                            aria-label="Tăng"
                            className="flex h-7 w-7 items-center justify-center text-ink transition hover:text-clay-600"
                          >
                            <Plus className="h-3 w-3" strokeWidth={2} />
                          </button>
                        </div>
                        <p className="text-sm font-bold text-clay-600">
                          <CountUp value={item.price * item.qty} suffix="đ" duration={0.5} />
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div
              className="border-t border-sand-200 bg-white px-5 py-4 shadow-lg"
              style={{ paddingBottom: "calc(env(safe-area-inset-bottom) + 1.2rem)" }}
            >
              <div className="space-y-1.5 pb-3 text-xs text-mute">
                <div className="flex items-center justify-between">
                  <span>Đã chọn ({selectedCount} món)</span>
                  <span className="font-semibold text-ink">{formatMoney(selectedSubtotal)}</span>
                </div>
                <div className="flex items-center justify-between font-medium text-emerald-700">
                  <span>Phí vận chuyển</span>
                  <span>0đ nếu QR · 30.000đ nếu COD</span>
                </div>
              </div>

              <div className="flex items-center justify-between border-t border-sand-200 pt-3">
                <span className="text-sm font-bold text-ink">Tổng món đã chọn:</span>
                <span className="font-display text-xl font-bold tabular-nums text-clay-600">
                  <CountUp value={selectedSubtotal} suffix="đ" duration={0.7} />
                </span>
              </div>

              <button
                onClick={goCheckout}
                disabled={!selectedItems.length}
                className="mt-3 flex w-full items-center justify-center gap-2 rounded-full bg-ink py-4 text-xs font-bold uppercase tracking-wider text-white shadow-lg transition hover:bg-clay-600 active:scale-[0.99] disabled:opacity-40"
              >
                <span>Thanh toán {selectedCount > 0 ? `${selectedCount} món` : "món đã chọn"}</span>
                <ArrowRight className="h-4 w-4" />
              </button>
            </div>
          </>
        )}
      </motion.aside>
    </motion.div>
  );
}

function SelectMark({ checked }: { checked: boolean }) {
  return (
    <span
      className={cn(
        "flex h-5 w-5 items-center justify-center rounded-md border-2 transition",
        checked ? "border-clay-500 bg-clay-500" : "border-sand-300 bg-white"
      )}
    >
      {checked && <Check className="h-3 w-3 text-white" strokeWidth={3} />}
    </span>
  );
}
