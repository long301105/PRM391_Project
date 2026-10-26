"use client";

import { motion } from "framer-motion";
import {
  ArrowLeft,
  CheckCircle2,
  Clock,
  PackageCheck,
  Search,
  Truck,
  X,
  XCircle,
} from "lucide-react";
import { useEffect, useState } from "react";
import { fetchMyOrderByNumber } from "@/api/orders";
import { useAuth } from "@/context/AuthContext";
import { ApiError } from "@/lib/api";
import { useCart, type OrderRecord } from "@/context/CartContext";
import { formatMoney } from "@/lib/format";
import { cn } from "@/utils/cn";

interface OrderLookupModalProps {
  initialCode?: string;
  onClose: () => void;
  variant?: "modal" | "page";
}

const STATUS_STEPS = [
  { id: "pending", label: "Tiếp nhận đơn", icon: Clock },
  { id: "confirmed", label: "Đã xác nhận", icon: CheckCircle2 },
  { id: "shipping", label: "Đang vận chuyển", icon: Truck },
  { id: "completed", label: "Giao thành công", icon: PackageCheck },
];

export function OrderLookupModal({
  initialCode = "",
  onClose,
  variant = "modal",
}: OrderLookupModalProps) {
  const { lookupOrder, rememberOrder } = useCart();
  const { isAuthenticated, requireLogin } = useAuth();
  const [query, setQuery] = useState(initialCode);
  const [searched, setSearched] = useState(false);
  const [order, setOrder] = useState<OrderRecord | null>(null);
  const [loading, setLoading] = useState(false);
  const [lookupError, setLookupError] = useState<string | null>(null);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  useEffect(() => {
    if (initialCode) {
      handleSearch(initialCode);
    }
  }, [initialCode]);

  const handleSearch = async (searchVal?: string) => {
    const q = (searchVal ?? query).trim();
    if (!q) return;

    setSearched(true);
    setLookupError(null);

    const local = lookupOrder(q);
    if (local) setOrder(local);

    const looksLikePhone = /^[0-9+\s]+$/.test(q);
    if (looksLikePhone) {
      if (!local) {
        setOrder(null);
        setLookupError(
          isAuthenticated
            ? "Không tìm thấy đơn nào với số điện thoại này trong các đơn đã tải. Hãy tra bằng mã đơn."
            : "Đăng nhập để xem đơn hàng của bạn."
        );
      }
      return;
    }

    if (!isAuthenticated) {
      setOrder(local ?? null);
      if (!local) {
        setLookupError("Đăng nhập để tra cứu đơn hàng của bạn.");
        requireLogin();
      }
      return;
    }

    setLoading(true);
    try {
      const found = await fetchMyOrderByNumber(q);
      setOrder(found);
      rememberOrder(found);
    } catch (err) {
      if (!local) {
        setOrder(null);
        setLookupError(
          err instanceof ApiError
            ? err.status === 404
              ? `Không tìm thấy đơn ${q.toUpperCase()} trong tài khoản này.`
              : err.message
            : "Không tra cứu được đơn hàng. Vui lòng thử lại."
        );
      }
    } finally {
      setLoading(false);
    }
  };

  const getStepIndex = (status: string) => {
    if (status === "cancelled") return -1;
    const idx = STATUS_STEPS.findIndex((s) => s.id === status);
    return idx >= 0 ? idx : 0;
  };

  const currentStep = order ? getStepIndex(order.status) : 0;

  const inner = (
    <>
        <div className="flex items-center gap-2 text-clay-500 text-xs font-bold uppercase tracking-wider">
          <Truck className="h-4 w-4" />
          <span>LA BOUTIQUE VN · Tra cứu đơn hàng</span>
        </div>

        <h2 className="mt-1 font-display text-2xl font-bold text-ink">
          Theo dõi tiến độ vận chuyển
        </h2>
        <p className="mt-1 text-xs text-mute">
          Nhập mã đơn hàng (ví dụ: <strong className="text-ink">LBVN-2608-X8YZ</strong>) hoặc số điện thoại đã đặt hàng.
        </p>

        {/* Search input */}
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleSearch();
          }}
          className="mt-4 flex gap-2"
        >
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-mute" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Nhập mã đơn hoặc số điện thoại..."
              className="w-full rounded-2xl border border-sand-300 bg-sand-50 py-3 pl-10 pr-4 text-sm text-ink outline-none transition focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
            />
          </div>
          <button
            type="submit"
            disabled={!query.trim()}
            className="flex items-center justify-center rounded-2xl bg-clay-500 px-6 text-xs font-bold uppercase tracking-wider text-white shadow transition hover:bg-clay-600 active:scale-95 disabled:opacity-50"
          >
            Tra cứu
          </button>
        </form>

        {/* Search Results */}
        {searched && (
          <div className="mt-6">
            {!order ? (
              <div className="rounded-2xl bg-sand-100 p-5 text-center text-xs text-mute border border-sand-200">
                <p className="font-semibold text-ink">Không tìm thấy đơn hàng với thông tin đã nhập.</p>
                <p className="mt-1">Nàng hãy kiểm tra lại mã đơn hàng hoặc số điện thoại nhé.</p>
              </div>
            ) : (
              <div className="rounded-2xl border border-sand-200 bg-sand-50/80 p-5 shadow-sm">
                {/* Header */}
                <div className="flex flex-wrap items-center justify-between gap-2 border-b border-sand-200 pb-3">
                  <div>
                    <span className="text-[10px] uppercase font-bold text-mute">Mã đơn hàng</span>
                    <p className="font-mono text-base font-bold text-clay-600">
                      {order.orderNumber}
                    </p>
                  </div>
                  <span
                    className={cn(
                      "rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wider",
                      order.status === "completed"
                        ? "bg-emerald-100 text-emerald-800"
                        : order.status === "cancelled"
                        ? "bg-rose-100 text-rose-800"
                        : "bg-amber-100 text-amber-800"
                    )}
                  >
                    {order.status === "pending" && "Đang tiếp nhận"}
                    {order.status === "confirmed" && "Đã xác nhận"}
                    {order.status === "shipping" && "Đang giao hàng"}
                    {order.status === "completed" && "Giao thành công"}
                    {order.status === "cancelled" && "Đã hủy"}
                  </span>
                </div>

                {/* Status Timeline */}
                {order.status !== "cancelled" ? (
                  <div className="my-6">
                    <div className="grid grid-cols-4 gap-2 text-center">
                      {STATUS_STEPS.map((s, idx) => {
                        const Icon = s.icon;
                        const isDone = idx <= currentStep;
                        const isCurrent = idx === currentStep;

                        return (
                          <div key={s.id} className="flex flex-col items-center">
                            <div
                              className={cn(
                                "flex h-10 w-10 items-center justify-center rounded-full transition shadow-sm",
                                isDone
                                  ? "bg-clay-500 text-white"
                                  : "bg-sand-200 text-mute",
                                isCurrent && "ring-4 ring-clay-200 scale-110"
                              )}
                            >
                              <Icon className="h-5 w-5" />
                            </div>
                            <span
                              className={cn(
                                "mt-2 text-[11px] font-semibold leading-tight",
                                isDone ? "text-ink font-bold" : "text-mute"
                              )}
                            >
                              {s.label}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ) : (
                  <div className="my-4 flex items-center gap-2 rounded-xl bg-rose-100/60 p-3 text-xs text-rose-800">
                    <XCircle className="h-4 w-4" />
                    <span>Đơn hàng đã được hủy theo yêu cầu.</span>
                  </div>
                )}

                {/* Recipient Details */}
                <div className="space-y-1.5 border-t border-sand-200 pt-3 text-xs text-mute">
                  <p>
                    <strong className="text-ink">Người nhận:</strong> {order.customerName} ({order.phone})
                  </p>
                  <p>
                    <strong className="text-ink">Địa chỉ:</strong> {order.address}
                  </p>
                  <p>
                    <strong className="text-ink">Thanh toán:</strong>{" "}
                    {order.paymentMethod === "qr"
                      ? "Chuyển khoản VietQR (Freeship)"
                      : "COD (Thu tiền tận nơi)"}
                  </p>
                </div>

                {/* Items */}
                <div className="mt-4 border-t border-sand-200 pt-3">
                  <p className="text-xs font-bold uppercase text-ink mb-2">Sản phẩm đã đặt</p>
                  <div className="space-y-2 max-h-48 overflow-y-auto soft-scroll">
                    {order.items?.map((it, i) => (
                      <div key={i} className="flex items-center gap-3 bg-white p-2 rounded-xl border border-sand-200">
                        <img src={it.img} alt={it.name} className="h-12 w-10 rounded-lg object-cover" />
                        <div className="flex-1 min-w-0">
                          <p className="text-xs font-bold text-ink truncate">{it.name}</p>
                          <p className="text-[11px] text-mute">Size: {it.size} · Số lượng: {it.qty}</p>
                        </div>
                        <p className="text-xs font-bold text-clay-600">{formatMoney(it.price * it.qty)}</p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Total */}
                <div className="mt-4 flex items-center justify-between border-t border-sand-200 pt-3 text-sm font-bold text-ink">
                  <span>Tổng tiền đơn hàng:</span>
                  <span className="font-display text-base text-clay-600">{formatMoney(order.total)}</span>
                </div>
              </div>
            )}
          </div>
        )}
    </>
  );

  if (variant === "page") {
    return (
      <div className="min-h-[70vh] bg-sand-50 px-4 pt-24 pb-20 sm:px-6">
        <div className="mx-auto max-w-xl">
          <button
            onClick={onClose}
            className="mb-4 inline-flex items-center gap-1 text-[11px] font-bold uppercase tracking-wider text-clay-600 hover:text-ink transition"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            Quay lại
          </button>
          <div className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-sand-200 sm:p-8">
            {inner}
          </div>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
      className="fixed inset-0 z-[3200] flex items-center justify-center bg-ink/70 p-3 backdrop-blur-sm sm:p-5"
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 8 }}
        transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
        onClick={(e) => e.stopPropagation()}
        className="soft-scroll relative max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-3xl bg-white p-6 shadow-2xl sm:p-8"
      >
        <button
          onClick={onClose}
          aria-label="Đóng"
          className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-full text-mute transition hover:bg-sand-100 hover:text-ink"
        >
          <X className="h-5 w-5" strokeWidth={1.8} />
        </button>
        {inner}
      </motion.div>
    </motion.div>
  );
}
