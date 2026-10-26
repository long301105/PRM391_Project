"use client";

import { AnimatePresence, motion } from "framer-motion";
import { ChevronLeft, ChevronRight, PenLine, Star, X } from "lucide-react";
import { useMemo, useState } from "react";
import type { FormEvent } from "react";
import { Dropdown } from "@/components/Dropdown";
import { useToast } from "@/context/ToastContext";
import { cn } from "@/utils/cn";

const COLORS = [
  "#fef08a", // Soft Yellow
  "#fbcfe8", // Soft Rose Pink
  "#bae6fd", // Soft Ocean Sky
  "#bbf7d0", // Soft Mint Green
  "#fed7aa", // Soft Terracotta Peach
  "#ddd6fe", // Soft Lavender Purple
];

const ROT = [-2.2, 1.8, -1.2, 2.3, -1.6, 1.4, -2.4, 1.1, -1.5, 2.0, -2.5, 0.8];
const BOARD = "#a9744b";
const PER_PAGE = 6;

interface ReviewItem {
  id?: number;
  name: string;
  rating: number;
  dateLabel?: string;
  text: string;
  colorIndex?: number;
}

const SEED: ReviewItem[] = [
  { name: "Minh Anh", rating: 5, dateLabel: "2 tuần trước", text: "Váy lụa mặc đi biển quá đã, mát mẻ và lên form cực kỳ tôn dáng. Mình đã giới thiệu cho cả hội bạn!", colorIndex: 0 },
  { name: "Khánh Linh", rating: 5, dateLabel: "1 tháng trước", text: "Chất linen thoáng mát, giặt máy nhiều lần vẫn giữ form. Màu y hình shop nhé.", colorIndex: 1 },
  { name: "Thu Hà", rating: 4, dateLabel: "3 tuần trước", text: "Đầm đẹp, đường may chỉn chu. Giao hàng nhanh, đóng hộp sang xịn mịn.", colorIndex: 2 },
  { name: "Bảo Ngọc", rating: 5, dateLabel: "1 tuần trước", text: "Cover-up mặc lớp ngoài bikini cực xinh, ánh nắng chiều lên ảnh sống ảo siêu đỉnh.", colorIndex: 3 },
  { name: "Phương Vy", rating: 5, dateLabel: "5 ngày trước", text: "Lần đầu mua ở LA Boutique mà cực ấn tượng, bao bì đẹp, có cả thư cảm ơn tay.", colorIndex: 4 },
  { name: "Hoàng Oanh", rating: 5, dateLabel: "2 tháng trước", text: "Form chuẩn, mình 52kg mặc size M vừa đẹp. Sẽ ủng hộ bộ sưu tập tiếp theo.", colorIndex: 5 },
  { name: "Diệu Anh", rating: 5, dateLabel: "10 ngày trước", text: "Quần ống suông mix với áo hai dây là chân ái đi biển. Vải xịn, không bị xù lông.", colorIndex: 0 },
  { name: "Thanh Trúc", rating: 5, dateLabel: "1 tháng trước", text: "Set đồ đi Phuket vừa xinh vừa gọn vali. Nhận được rất nhiều lời khen ngợi.", colorIndex: 1 },
  { name: "Mai Chi", rating: 4, dateLabel: "3 tuần trước", text: "Chất vải mềm mát, màu sắc trang nhã tôn da. Rất hợp cho các chuyến du lịch hè.", colorIndex: 2 },
  { name: "Lam Uyên", rating: 5, dateLabel: "4 ngày trước", text: "Đóng gói chỉn chu, có quà nhỏ kèm. Sản phẩm đúng mô tả, sẽ mua thêm màu khác.", colorIndex: 3 },
];

const SORTS = [
  { id: "new", label: "Mới nhất" },
  { id: "high", label: "Đánh giá 5 sao" },
  { id: "low", label: "Tất cả sao" },
];

export function ReviewsBoard({ productId }: { productId?: string }) {
  const { showToast } = useToast();
  const [reviews, setReviews] = useState<ReviewItem[]>(SEED);
  const [sort, setSort] = useState("new");
  const [page, setPage] = useState(0);
  const [creating, setCreating] = useState(false);

  const [fName, setFName] = useState("");
  const [fRating, setFRating] = useState(5);
  const [fText, setFText] = useState("");
  const [fColor, setFColor] = useState(0);

  const sorted = useMemo(() => {
    const arr = [...reviews];
    if (sort === "high") arr.sort((a, b) => b.rating - a.rating);
    else if (sort === "low") arr.sort((a, b) => a.rating - b.rating);
    return arr;
  }, [reviews, sort]);

  const totalPages = Math.max(1, Math.ceil(sorted.length / PER_PAGE));
  const safePage = Math.min(page, totalPages - 1);
  const pageItems = sorted.slice(safePage * PER_PAGE, safePage * PER_PAGE + PER_PAGE);
  const avg = (
    reviews.reduce((s, r) => s + r.rating, 0) / Math.max(1, reviews.length)
  ).toFixed(1);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!fName.trim() || !fText.trim()) return;

    const newRev: ReviewItem = {
      name: fName.trim(),
      rating: fRating,
      text: fText.trim(),
      colorIndex: fColor,
      dateLabel: "Vừa xong",
    };

    setReviews((prev) => [newRev, ...prev]);
    showToast("Đã đính note đánh giá lên bảng thành công!");
    setSort("new");
    setPage(0);
    setFName("");
    setFRating(5);
    setFText("");
    setFColor(0);
    setCreating(false);
  };

  return (
    <section className="mt-14">
      {/* Header */}
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h3 className="font-display text-2xl font-bold text-ink sm:text-3xl">
            Cảm nhận từ khách hàng
          </h3>
          <p className="mt-1 text-xs text-mute">Những lời nhắn yêu thương từ các nàng đã mặc thử</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-1.5 rounded-full bg-white px-3.5 py-2 text-xs ring-1 ring-sand-200 shadow-sm">
            <Star className="h-4 w-4 text-amber-500" fill="currentColor" strokeWidth={0} />
            <span className="font-bold text-ink">{avg}</span>
            <span className="text-mute">/ 5.0 ({reviews.length} đánh giá)</span>
          </div>
          <Dropdown
            value={sort}
            options={SORTS}
            onChange={(v) => {
              setSort(v);
              setPage(0);
            }}
            size="sm"
            active={sort !== "new"}
          />
          <button
            onClick={() => setCreating((v) => !v)}
            className="flex h-[38px] items-center gap-1.5 rounded-full bg-clay-500 px-4 text-xs font-bold uppercase tracking-wider text-white shadow transition hover:bg-clay-600 active:scale-95"
          >
            {creating ? <X className="h-4 w-4" strokeWidth={2} /> : <PenLine className="h-4 w-4" strokeWidth={1.8} />}
            {creating ? "Đóng" : "Gửi cảm nhận"}
          </button>
        </div>
      </div>

      {/* Form tạo đánh giá */}
      <AnimatePresence initial={false}>
        {creating && (
          <motion.form
            onSubmit={handleSubmit}
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.3 }}
            className="overflow-hidden"
          >
            <div className="mt-4 rounded-3xl border border-sand-200 bg-sand-50/90 p-4 sm:p-6 shadow-sm">
              <div className="grid gap-3 sm:grid-cols-2">
                <div>
                  <label className="mb-1 block text-xs font-bold uppercase text-ink">Họ tên nàng</label>
                  <input
                    value={fName}
                    onChange={(e) => setFName(e.target.value)}
                    required
                    maxLength={40}
                    placeholder="Ví dụ: Phương Vy (Sài Gòn)"
                    className="w-full rounded-xl border border-sand-200 bg-white px-3.5 py-2.5 text-xs text-ink outline-none transition focus:border-clay-400 focus:ring-2 focus:ring-clay-200"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-bold uppercase text-ink">Đánh giá sao</label>
                  <div className="flex h-[38px] items-center gap-1.5 px-1">
                    {[1, 2, 3, 4, 5].map((n) => (
                      <button
                        type="button"
                        key={n}
                        onClick={() => setFRating(n)}
                        aria-label={`${n} sao`}
                        className="text-amber-400 transition hover:scale-125 active:scale-95"
                      >
                        <Star
                          className="h-5 w-5"
                          fill={n <= fRating ? "currentColor" : "none"}
                          strokeWidth={1.5}
                        />
                      </button>
                    ))}
                    <span className="ml-2 text-xs font-semibold text-mute">
                      {fRating === 5 ? "Rất ưng ý (5 sao)" : `${fRating} sao`}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-3">
                <label className="mb-1 block text-xs font-bold uppercase text-ink">Cảm nhận sản phẩm</label>
                <textarea
                  value={fText}
                  onChange={(e) => setFText(e.target.value)}
                  required
                  maxLength={280}
                  rows={3}
                  placeholder="Chia sẻ về độ rủ, sự thoáng mát của chất liệu tơ tằm, linen và cảm xúc khi diện đồ..."
                  className="w-full resize-none rounded-xl border border-sand-200 bg-white px-3.5 py-2.5 text-xs text-ink outline-none transition focus:border-clay-400 focus:ring-2 focus:ring-clay-200"
                />
              </div>

              <div className="mt-3 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-mute">Màu note:</span>
                  <div className="flex gap-2">
                    {COLORS.map((c, i) => (
                      <button
                        type="button"
                        key={i}
                        onClick={() => setFColor(i)}
                        aria-label={`Màu ${i + 1}`}
                        style={{ backgroundColor: c }}
                        className={cn(
                          "h-6 w-6 rounded-full border border-black/10 shadow-sm transition",
                          i === fColor ? "ring-2 ring-ink ring-offset-2 scale-110" : "hover:scale-105"
                        )}
                      />
                    ))}
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setCreating(false)}
                    className="rounded-full border border-sand-200 bg-white px-4 py-2 text-xs font-bold text-mute transition hover:border-sand-300"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={!fName.trim() || !fText.trim()}
                    className="rounded-full bg-ink px-5 py-2 text-xs font-bold uppercase tracking-wider text-white shadow transition hover:bg-clay-600 active:scale-95 disabled:opacity-50"
                  >
                    Dán note lên bảng
                  </button>
                </div>
              </div>
            </div>
          </motion.form>
        )}
      </AnimatePresence>

      {/* Bảng gỗ / Corkboard */}
      <div
        className="relative mt-6 overflow-hidden rounded-3xl p-5 sm:p-7 shadow-xl"
        style={{
          backgroundColor: BOARD,
          backgroundImage:
            "radial-gradient(circle, rgba(255,255,255,0.06) 1px, transparent 1px), repeating-linear-gradient(90deg, rgba(0,0,0,0.05) 0px, rgba(0,0,0,0.05) 1px, transparent 1px, transparent 12px), linear-gradient(180deg, rgba(255,255,255,0.1), rgba(0,0,0,0.2))",
          boxShadow: "inset 0 0 20px rgba(0,0,0,0.3), 0 8px 30px rgba(0,0,0,0.15)",
        }}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={`${safePage}-${sort}`}
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -30 }}
            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3"
          >
            {pageItems.map((r, i) => {
              const gi = safePage * PER_PAGE + i;
              const color =
                r.colorIndex != null ? COLORS[r.colorIndex % COLORS.length] : COLORS[gi % COLORS.length];
              const rot = ROT[gi % ROT.length];

              return (
                <motion.div
                  key={gi}
                  style={{
                    backgroundColor: color,
                    transform: `rotate(${rot}deg)`,
                  }}
                  whileHover={{ scale: 1.03, rotate: 0, zIndex: 20 }}
                  transition={{ type: "spring", stiffness: 400, damping: 25 }}
                  className="group relative flex flex-col justify-between rounded-xl p-5 shadow-md shadow-ink/15 transition-shadow hover:shadow-2xl"
                >
                  {/* Push Pin */}
                  <div className="absolute -top-2 left-1/2 -translate-x-1/2">
                    <div className="h-4 w-4 rounded-full bg-gradient-to-br from-rose-400 to-rose-700 shadow-md ring-1 ring-white/50" />
                    <div className="mx-auto -mt-1 h-2 w-1 bg-neutral-400 rounded-sm" />
                  </div>

                  <div>
                    {/* Stars */}
                    <div className="mb-2 flex items-center justify-between">
                      <div className="flex gap-0.5 text-amber-500">
                        {Array.from({ length: 5 }).map((_, si) => (
                          <Star
                            key={si}
                            className="h-3.5 w-3.5"
                            fill={si < r.rating ? "currentColor" : "none"}
                            strokeWidth={1.5}
                          />
                        ))}
                      </div>
                      <span className="text-[11px] font-medium text-ink/60">
                        {r.dateLabel || "Gần đây"}
                      </span>
                    </div>

                    {/* Content */}
                    <p className="font-sans text-[13px] leading-relaxed text-ink font-medium">
                      &ldquo;{r.text}&rdquo;
                    </p>
                  </div>

                  {/* Author */}
                  <div className="mt-4 flex items-center justify-between border-t border-black/10 pt-2 text-xs">
                    <span className="font-display font-bold uppercase tracking-wider text-ink">
                      {r.name}
                    </span>
                    <span className="text-[10px] uppercase tracking-wider text-clay-700 font-bold">
                      Đã mua hàng
                    </span>
                  </div>
                </motion.div>
              );
            })}
          </motion.div>
        </AnimatePresence>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="mt-7 flex items-center justify-center gap-3">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0}
              className="flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-ink shadow backdrop-blur transition hover:bg-white disabled:opacity-40"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <span className="text-xs font-bold tracking-wider text-white drop-shadow">
              Trang {safePage + 1} / {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1}
              className="flex h-9 w-9 items-center justify-center rounded-full bg-white/90 text-ink shadow backdrop-blur transition hover:bg-white disabled:opacity-40"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
