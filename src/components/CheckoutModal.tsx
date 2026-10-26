"use client";

import { motion } from "framer-motion";
import { Check, Copy, QrCode, Truck, Wallet, X } from "lucide-react";
import { useEffect, useState } from "react";
import { useCart, type CartItem, type OrderRecord } from "@/context/CartContext";
import { useAuth } from "@/context/AuthContext";
import { placeOrder } from "@/api/orders";
import { ApiError } from "@/lib/api";
import { useToast } from "@/context/ToastContext";
import { CountUp } from "@/components/lightswind/count-up";
import { formatMoney } from "@/lib/format";
import { cn } from "@/utils/cn";

interface CheckoutModalProps {
  onClose: () => void;
  onSuccess: (order: OrderRecord) => void;
  itemsOverride?: CartItem[] | null;
  intent?: "buynow" | "cart";
}

export function CheckoutModal({
  onClose,
  onSuccess,
  itemsOverride = null,
  intent = "cart",
}: CheckoutModalProps) {
  const { items: cartItems, clear, rememberOrder } = useCart();
  const { isAuthenticated, requireLogin } = useAuth();
  const { showToast } = useToast();
  const isDirect = Array.isArray(itemsOverride);
  const items = isDirect ? itemsOverride : cartItems;
  const subtotal = items.reduce((s, it) => s + it.price * it.qty, 0);
  const itemCount = items.reduce((s, it) => s + it.qty, 0);

  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [address, setAddress] = useState("");
  const [note, setNote] = useState("");
  const [payment, setPayment] = useState<"cod" | "qr">("qr");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const FREE_SHIPPING_THRESHOLD = 1_000_000;
  const shipping = payment === "qr" || subtotal >= FREE_SHIPPING_THRESHOLD ? 0 : 30000;
  const total = subtotal + shipping;
  const qrMemo = `LBVN ${phone.replace(/\s+/g, "").slice(-4) || "0000"}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=260x260&margin=8&data=${encodeURIComponent(
    `LA BOUTIQUE VN\nSo tien: ${total}d\nNoi dung: ${qrMemo}`
  )}`;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isAuthenticated) {
      showToast("Đăng nhập để đặt hàng.", "info");
      requireLogin();
      return;
    }

    if (!name.trim() || !phone.trim() || !address.trim()) {
      showToast("Vui lòng điền họ tên, số điện thoại và địa chỉ nhận hàng.", "info");
      return;
    }

    if (items.length === 0) {
      showToast("Chưa có sản phẩm để thanh toán.", "info");
      return;
    }

    setLoading(true);
    try {
      const created = await placeOrder({
        customerName: name,
        phone,
        email: email.trim() || undefined,
        address,
        note: note.trim() || undefined,
        paymentMethod: payment,
        items: [...items],
      });

      rememberOrder(created);
      if (!isDirect) clear();
      onSuccess(created);
    } catch (err) {
      if (err instanceof ApiError && err.isUnauthorized) {
        showToast("Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.", "info");
        requireLogin();
      } else {
        showToast(
          err instanceof ApiError ? err.message : "Đặt hàng không thành công. Vui lòng thử lại.",
          "info"
        );
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
      className="fixed inset-0 z-[3100] flex items-center justify-center bg-ink/65 p-3 backdrop-blur-sm sm:p-5"
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 18 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 8 }}
        transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
        onClick={(e) => e.stopPropagation()}
        className="soft-scroll relative max-h-[92vh] w-full max-w-lg overflow-y-auto rounded-3xl bg-white p-6 shadow-2xl sm:p-8"
      >
        <button
          onClick={onClose}
          aria-label="Đóng"
          className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-full text-mute transition hover:bg-sand-100 hover:text-ink"
        >
          <X className="h-5 w-5" strokeWidth={1.8} />
        </button>

        <h2 className="font-display text-2xl font-bold text-ink">
          {intent === "buynow" ? "Mua ngay" : "Thanh toán đơn hàng"}
        </h2>
        <p className="mt-1 text-xs text-mute">
          {intent === "buynow"
            ? "Chỉ thanh toán sản phẩm này. Đóng cửa sổ sẽ không thêm vào giỏ."
            : "Chỉ tính món đã chọn. Các món còn lại vẫn nằm trong giỏ."}
        </p>

        <div className="mt-4 rounded-2xl bg-sand-50 p-3.5 border border-sand-200">
          <p className="text-[11px] font-bold uppercase tracking-wider text-mute mb-2">
            {intent === "buynow"
              ? `Sản phẩm mua ngay (${itemCount} món)`
              : `Món đã chọn (${itemCount} món)`}
            :
          </p>
          <div className="max-h-36 overflow-y-auto soft-scroll space-y-2">
            {items.map((it, idx) => (
              <div key={idx} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 truncate">
                  <img src={it.img} alt={it.name} className="h-9 w-8 rounded-md object-cover" />
                  <span className="font-medium text-ink truncate">{it.name}</span>
                  <span className="font-bold text-clay-700 bg-clay-100 px-1.5 py-0.2 rounded text-[10px]">
                    Size {it.size} x{it.qty}
                  </span>
                </div>
                <span className="font-bold tabular-nums text-clay-600 shrink-0 ml-2">
                  {formatMoney(it.price * it.qty)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {!isAuthenticated && (
          <button
            type="button"
            onClick={requireLogin}
            className="mt-4 flex w-full items-center justify-between gap-3 rounded-2xl border border-amber-300 bg-amber-50 px-4 py-3 text-left"
          >
            <span className="text-xs leading-relaxed text-amber-800">
              Cần đăng nhập để đặt hàng — đơn được lưu vào tài khoản để nàng tra cứu về sau.
            </span>
            <span className="shrink-0 rounded-full bg-ink px-3.5 py-1.5 text-[11px] font-bold uppercase tracking-wider text-white">
              Đăng nhập
            </span>
          </button>
        )}

        <form onSubmit={handleSubmit} className="mt-4 space-y-3">
          {/* Customer Name */}
          <div>
            <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-ink">
              Họ và tên người nhận <span className="text-rose-500">*</span>
            </label>
            <input
              required
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ví dụ: Nguyễn Phương Linh"
              className="w-full rounded-xl border border-sand-200 bg-sand-50/70 px-4 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
            />
          </div>

          {/* Phone + Email */}
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-ink">
                Số điện thoại <span className="text-rose-500">*</span>
              </label>
              <input
                required
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="0909 123 456"
                className="w-full rounded-xl border border-sand-200 bg-sand-50/70 px-4 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-ink">
                Email nhận hóa đơn
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="phuonglinh@gmail.com"
                className="w-full rounded-xl border border-sand-200 bg-sand-50/70 px-4 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
              />
            </div>
          </div>

          {/* Address */}
          <div>
            <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-ink">
              Địa chỉ nhận hàng cụ thể <span className="text-rose-500">*</span>
            </label>
            <textarea
              required
              rows={2}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Số nhà, tên đường, phường/xã, quận/huyện, TP..."
              className="w-full resize-none rounded-xl border border-sand-200 bg-sand-50/70 px-4 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
            />
          </div>

          {/* Note */}
          <div>
            <label className="mb-1 block text-xs font-bold uppercase tracking-wider text-ink">
              Ghi chú đóng gói / giao hàng (Tùy chọn)
            </label>
            <input
              type="text"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Giao giờ hành chính, gọi trước khi giao..."
              className="w-full rounded-xl border border-sand-200 bg-sand-50/70 px-4 py-2 text-xs text-ink outline-none transition focus:border-clay-400 focus:bg-white"
            />
          </div>

          <div className="space-y-2.5 pt-1">
            <p className="text-xs font-bold uppercase tracking-wider text-ink">
              Phương thức thanh toán
            </p>

            <button
              type="button"
              onClick={() => setPayment("qr")}
              className={cn(
                "flex w-full items-center gap-3.5 rounded-2xl border p-3.5 text-left transition active:scale-98",
                payment === "qr"
                  ? "border-clay-500 bg-clay-50/90 shadow-sm"
                  : "border-sand-200 bg-white hover:border-sand-300"
              )}
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-clay-500 text-white shadow-sm">
                <QrCode className="h-5 w-5" />
              </div>
              <span className="flex-1">
                <span className="flex items-center gap-2 text-sm font-bold text-ink">
                  <span>Chuyển khoản VietQR</span>
                  <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-800">
                    Freeship 0đ
                  </span>
                </span>
                <span className="mt-0.5 block text-xs text-mute">
                  Quét mã bằng App ngân hàng — miễn phí giao hàng toàn quốc
                </span>
              </span>
              <span
                className={cn(
                  "flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2 transition",
                  payment === "qr" ? "border-clay-500 bg-clay-500" : "border-sand-300"
                )}
              >
                {payment === "qr" && <Check className="h-3 w-3 text-white" strokeWidth={3} />}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setPayment("cod")}
              className={cn(
                "flex w-full items-center gap-3.5 rounded-2xl border p-3.5 text-left transition active:scale-98",
                payment === "cod"
                  ? "border-clay-500 bg-clay-50/90 shadow-sm"
                  : "border-sand-200 bg-white hover:border-sand-300"
              )}
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-sand-200 text-ink">
                <Wallet className="h-5 w-5" />
              </div>
              <span className="flex-1">
                <span className="block text-sm font-bold text-ink">COD — Thanh toán khi nhận hàng</span>
                <span className="mt-0.5 block text-xs text-mute">Phí ship toàn quốc: +30.000đ</span>
              </span>
              <span
                className={cn(
                  "flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2 transition",
                  payment === "cod" ? "border-clay-500 bg-clay-500" : "border-sand-300"
                )}
              >
                {payment === "cod" && <Check className="h-3 w-3 text-white" strokeWidth={3} />}
              </span>
            </button>

            {payment === "qr" && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                className="flex flex-col items-center overflow-hidden rounded-2xl border border-clay-300 bg-clay-50/60 p-4 text-center"
              >
                <p className="mb-2 text-xs font-bold uppercase tracking-wider text-clay-800">
                  Quét mã QR bằng App Ngân hàng
                </p>
                <div className="rounded-2xl bg-white p-2.5 shadow ring-1 ring-clay-200">
                  <img
                    src={qrUrl}
                    alt="Mã QR thanh toán LA BOUTIQUE VN"
                    className="h-44 w-44 rounded-lg object-contain"
                  />
                </div>
                <div className="mt-3 flex w-full max-w-xs items-center justify-between rounded-xl border border-clay-200 bg-white p-2.5 text-xs">
                  <div className="text-left">
                    <p className="font-bold text-ink">Nội dung CK: {qrMemo}</p>
                    <p className="text-[11px] text-mute">Số tiền {formatMoney(total)}</p>
                  </div>
                  <button
                    type="button"
                    onClick={async () => {
                      const text = `${qrMemo} — ${total}đ`;
                      try {
                        await navigator.clipboard.writeText(text);
                      } catch {
                        const ta = document.createElement("textarea");
                        ta.value = text;
                        document.body.appendChild(ta);
                        ta.select();
                        document.execCommand("copy");
                        document.body.removeChild(ta);
                      }
                      showToast("Đã sao chép nội dung chuyển khoản!");
                    }}
                    className="flex items-center gap-1 rounded-lg bg-clay-100 px-2.5 py-1 text-xs font-bold text-clay-700 hover:bg-clay-200"
                  >
                    <Copy className="h-3 w-3" />
                    Copy
                  </button>
                </div>
              </motion.div>
            )}
          </div>

          {/* Pricing Summary */}
          <div className="mt-4 space-y-1.5 rounded-2xl bg-sand-100 p-4 text-xs tabular-nums">
            <div className="flex justify-between text-mute">
              <span>Tạm tính</span>
              <span>{formatMoney(subtotal)}</span>
            </div>
            <div className="flex items-center justify-between text-mute">
              <span className="flex items-center gap-1">
                <Truck className="h-3.5 w-3.5" /> Phí vận chuyển
              </span>
              <span>{formatMoney(shipping)}</span>
            </div>
            <div className="flex justify-between border-t border-sand-200 pt-2 text-sm font-bold text-ink">
              <span>Tổng cộng thanh toán</span>
              <span className="font-display text-base font-bold text-clay-600">
                <CountUp value={total} suffix="đ" duration={0.8} />
              </span>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-ink py-4 text-xs font-bold uppercase tracking-wider text-white shadow-xl transition hover:bg-clay-600 active:scale-[0.99] disabled:opacity-50"
          >
            <span>
              {loading ? "Đang gửi đơn..." : `Hoàn tất đặt hàng — ${formatMoney(total)}`}
            </span>
          </button>
        </form>
      </motion.div>
    </motion.div>
  );
}
