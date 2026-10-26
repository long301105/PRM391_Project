"use client";

import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { X } from "lucide-react";
import { useAuth } from "@/context/AuthContext";
import { ApiError } from "@/lib/api";

export function LoginModal({ onClose }: { onClose: () => void }) {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password) {
      setError("Nhập email và mật khẩu.");
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await login(email, password);
    } catch (err) {
      setError(
        err instanceof ApiError ? err.message : "Đăng nhập không thành công. Vui lòng thử lại."
      );
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
      className="fixed inset-0 z-[4000] flex items-center justify-center bg-ink/65 p-4 backdrop-blur-sm"
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98 }}
        transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-sm rounded-3xl bg-white p-7 shadow-2xl"
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Đóng"
          className="absolute right-4 top-4 rounded-full p-1.5 text-mute transition hover:bg-sand-100"
        >
          <X className="h-4 w-4" />
        </button>

        <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-clay-500">
          La Boutique VN
        </p>
        <h2 className="mt-1 font-display text-2xl font-bold text-ink">Đăng nhập</h2>
        <p className="mt-1.5 text-xs leading-relaxed text-mute">
          Cần đăng nhập để đặt hàng và tra cứu đơn của mình.
        </p>

        <form onSubmit={handleSubmit} className="mt-5 space-y-3">
          <div>
            <label className="mb-1 block text-[11px] font-bold uppercase tracking-wider text-mute">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              className="w-full rounded-xl border border-sand-200 bg-sand-50 px-3.5 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400"
              placeholder="ban@email.com"
            />
          </div>

          <div>
            <label className="mb-1 block text-[11px] font-bold uppercase tracking-wider text-mute">
              Mật khẩu
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              className="w-full rounded-xl border border-sand-200 bg-sand-50 px-3.5 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <p className="rounded-xl bg-red-50 px-3 py-2 text-xs leading-relaxed text-red-700">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-full bg-ink py-3 text-xs font-bold uppercase tracking-wider text-white transition hover:bg-clay-600 disabled:opacity-60"
          >
            {loading ? "Đang đăng nhập..." : "Đăng nhập"}
          </button>
        </form>

        <p className="mt-4 text-[11px] leading-relaxed text-mute">
          Chưa có tài khoản? Đăng ký hiện chỉ có trên ứng dụng di động, vì cần xác minh mã OTP
          gửi qua email.
        </p>
      </motion.div>
    </motion.div>
  );
}
