"use client";

import { AnimatePresence, motion } from "framer-motion";
import {
  ArrowRight,
  ArrowUpDown,
  Check,
  ChevronDown,
  RotateCcw,
  Search,
  SlidersHorizontal,
  Sparkles,
  Tag,
  X,
} from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { PRICE_MAX, PRICE_MIN } from "@/data/products";
import { useCatalog } from "@/context/CatalogContext";
import type { Product } from "@/data/products";
import { formatMoney } from "@/lib/format";
import { Dropdown } from "@/components/Dropdown";
import { cn } from "@/utils/cn";

export const CATALOG_CATEGORIES = [
  { id: "all", label: "Tất cả", fullLabel: "Tất cả sản phẩm" },
  { id: "sunset", label: "BST Sunset", fullLabel: "La Boutique VN Sunset" },
  { id: "ao", label: "Áo & Đầm", fullLabel: "Áo, Đầm & Cổ Yếm" },
  { id: "quan", label: "Quần & Váy", fullLabel: "Quần & Chân Váy" },
];

const SUGGESTIONS = [
  "Set La Boutique Sunset",
  "Áo Cổ Yếm tơ xốp",
  "Áo Hai Dây Lụa",
  "Áo Sơ Mi Đũi",
  "Chân Váy lụa lửng",
  "Quần Short Linen",
  "Đầm lụa body",
  "Váy dệt kim xốp",
];

const PRESET_RANGES = [
  { label: "Dưới 300k", min: PRICE_MIN, max: 300000 },
  { label: "300k — 500k", min: 300000, max: 500000 },
  { label: "500k — 700k", min: 500000, max: 700000 },
  { label: "Trên 700k", min: 700000, max: PRICE_MAX },
];

const SORT_OPTIONS = [
  { id: "featured", label: "Gợi ý" },
  { id: "new", label: "Mới nhất" },
  { id: "price-asc", label: "Giá ↑" },
  { id: "price-desc", label: "Giá ↓" },
];

const shortMoney = (n: number) =>
  n >= 1000000
    ? `${(n / 1000000).toFixed(n % 1000000 ? 1 : 0)}Tr`
    : `${Math.round(n / 1000)}k`;

interface PriceRange {
  min: number;
  max: number;
}

interface FilterSidebarProps {
  categoryOptions?: { id: string; label: string; fullLabel: string }[];
  category: string;
  onCategory: (v: string) => void;
  search: string;
  onSearch: (v: string) => void;
  price: PriceRange;
  onPrice: (v: PriceRange) => void;
  sort: string;
  onSort: (v: string) => void;
  resultCount: number;
  onOpenProduct: (p: Product) => void;
  categoryCounts: Record<string, number>;
}

function DualRange({
  min,
  max,
  value,
  onChange,
}: {
  min: number;
  max: number;
  value: PriceRange;
  onChange: (v: PriceRange) => void;
}) {
  const pct = (v: number) => Math.max(0, Math.min(100, ((v - min) / (max - min)) * 100));
  return (
    <div className="relative h-6 w-full flex items-center">
      <div className="absolute h-1.5 w-full rounded-full bg-sand-200" />
      <div
        className="absolute h-1.5 rounded-full bg-clay-500 transition-all"
        style={{ left: `${pct(value.min)}%`, right: `${100 - pct(value.max)}%` }}
      />
      <input
        type="range"
        aria-label="Giá tối thiểu"
        className="dual-range absolute inset-0 h-6 w-full cursor-pointer"
        min={min}
        max={max}
        step={10000}
        value={value.min}
        onChange={(e) =>
          onChange({ min: Math.min(Number(e.target.value), value.max - 20000), max: value.max })
        }
      />
      <input
        type="range"
        aria-label="Giá tối đa"
        className="dual-range absolute inset-0 h-6 w-full cursor-pointer"
        min={min}
        max={max}
        step={10000}
        value={value.max}
        onChange={(e) =>
          onChange({ min: value.min, max: Math.max(Number(e.target.value), value.min + 20000) })
        }
      />
    </div>
  );
}

export function FilterSidebar({
  categoryOptions = CATALOG_CATEGORIES,
  category,
  onCategory,
  search,
  onSearch,
  price,
  onPrice,
  sort,
  onSort,
  resultCount,
  onOpenProduct,
  categoryCounts,
}: FilterSidebarProps) {
  const { products } = useCatalog();
  const [mobilePriceModal, setMobilePriceModal] = useState(false);
  const [mobileSearchModal, setMobileSearchModal] = useState(false);
  const [focused, setFocused] = useState(false);
  const [tempMin, setTempMin] = useState(price.min);
  const [tempMax, setTempMax] = useState(price.max);

  useEffect(() => {
    setTempMin(price.min);
    setTempMax(price.max);
  }, [price]);

  const q = search.trim().toLowerCase();
  const matches = q
    ? products.filter((p) => p.name.toLowerCase().includes(q)).slice(0, 6)
    : [];

  const isCustomPrice = price.min !== PRICE_MIN || price.max !== PRICE_MAX;
  const isFiltered = search.trim() !== "" || isCustomPrice || sort !== "featured" || category !== "all";

  const pushPrice = (v: PriceRange) => {
    setTempMin(v.min);
    setTempMax(v.max);
    onPrice(v);
  };

  const resetPrice = () => {
    setTempMin(PRICE_MIN);
    setTempMax(PRICE_MAX);
    onPrice({ min: PRICE_MIN, max: PRICE_MAX });
    setMobilePriceModal(false);
  };

  const resetAll = () => {
    onCategory("all");
    onSearch("");
    resetPrice();
    onSort("featured");
  };

  return (
    <>
      {/* ========================================================================= */}
      {/* 1. DESKTOP STICKY LEFT SIDEBAR (>= 1024px)                                */}
      {/* ========================================================================= */}
      <aside className="hidden lg:block w-72 shrink-0 self-start sticky top-20">
        <div className="space-y-5 rounded-3xl border border-sand-200/90 bg-white p-5 shadow-sm">
          {/* Header & Reset */}
          <div className="flex items-center justify-between pb-3 border-b border-sand-100">
            <div className="flex items-center gap-2">
              <SlidersHorizontal className="h-4 w-4 text-clay-600" />
              <h3 className="font-bold text-xs uppercase tracking-wider text-ink">Bộ lọc tìm kiếm</h3>
            </div>
            {isFiltered && (
              <button
                onClick={resetAll}
                className="text-[11px] font-bold text-clay-600 hover:text-ink transition flex items-center gap-1"
              >
                <RotateCcw className="h-3 w-3" />
                Đặt lại
              </button>
            )}
          </div>

          {/* Search box with live suggestions */}
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-mute" />
            <input
              type="text"
              value={search}
              onChange={(e) => onSearch(e.target.value)}
              onFocus={() => setFocused(true)}
              onBlur={() => setTimeout(() => setFocused(false), 200)}
              placeholder="Tìm kiếm sản phẩm..."
              className="w-full rounded-2xl border border-sand-200 bg-sand-50/70 py-2.5 pl-9 pr-8 text-xs text-ink outline-none transition placeholder:text-mute/70 focus:border-clay-400 focus:bg-white focus:ring-2 focus:ring-clay-200"
            />
            {search && (
              <button
                onClick={() => onSearch("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-mute hover:text-ink"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}

            {/* Suggestions Dropdown on Desktop */}
            <AnimatePresence>
              {focused && (
                <motion.div
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 6 }}
                  className="absolute left-0 right-0 top-[calc(100%+6px)] z-[200] overflow-hidden rounded-2xl border border-sand-200 bg-white shadow-xl shadow-ink/10"
                >
                  {q === "" ? (
                    <div className="p-3">
                      <p className="text-[10px] font-bold uppercase text-clay-600 mb-1.5">Gợi ý từ khóa:</p>
                      <div className="flex flex-wrap gap-1">
                        {SUGGESTIONS.slice(0, 4).map((s) => (
                          <button
                            key={s}
                            onMouseDown={(e) => {
                              e.preventDefault();
                              onSearch(s);
                            }}
                            className="rounded-lg border border-sand-200 bg-sand-50 px-2 py-1 text-[11px] font-medium text-ink hover:bg-clay-50 hover:text-clay-700"
                          >
                            {s}
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <ul className="max-h-48 overflow-y-auto soft-scroll p-1">
                      {matches.map((p) => (
                        <li key={p.id}>
                          <button
                            onMouseDown={(e) => {
                              e.preventDefault();
                              onOpenProduct(p);
                            }}
                            className="flex w-full items-center gap-2.5 rounded-xl p-2 text-left hover:bg-sand-50 transition"
                          >
                            <img src={p.img} alt={p.name} className="h-8 w-7 rounded object-cover" />
                            <div className="min-w-0 flex-1">
                              <p className="text-xs font-semibold text-ink truncate">{p.name}</p>
                              <p className="text-[10px] font-bold text-clay-600">{formatMoney(p.price)}</p>
                            </div>
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Vertical Category Menu on Left */}
          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-mute mb-2">
              Danh mục sản phẩm
            </p>
            <div className="space-y-1">
              {categoryOptions.map((c) => {
                const active = category === c.id;
                const count = categoryCounts[c.id];
                return (
                  <button
                    key={c.id}
                    onClick={() => onCategory(c.id)}
                    className={cn(
                      "flex w-full items-center justify-between rounded-xl px-3.5 py-2.5 text-left text-xs font-bold transition",
                      active
                        ? "bg-clay-500 text-white shadow-xs"
                        : "text-ink hover:bg-sand-100 hover:text-clay-600"
                    )}
                  >
                    <span>{c.fullLabel}</span>
                    {count !== undefined && <span
                      className={cn(
                        "rounded-full px-2 py-0.5 text-[10px]",
                        active ? "bg-white/20 text-white" : "bg-sand-100 text-mute"
                      )}
                    >
                      {count}
                    </span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Price Range Filter on Left */}
          <div className="pt-4 border-t border-sand-100">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-bold uppercase tracking-wider text-mute">
                Khoảng giá (VNĐ)
              </span>
              {isCustomPrice && (
                <button onClick={resetPrice} className="text-[10px] text-clay-600 hover:underline">
                  Mặc định
                </button>
              )}
            </div>

            <div className="mb-3 flex items-center justify-between text-xs font-bold text-clay-600">
              <span>{formatMoney(tempMin)}</span>
              <span>{formatMoney(tempMax)}</span>
            </div>

            <DualRange
              min={PRICE_MIN}
              max={PRICE_MAX}
              value={{ min: tempMin, max: tempMax }}
              onChange={pushPrice}
            />

            {/* Quick chips */}
            <div className="mt-3.5 grid grid-cols-2 gap-1.5">
              {PRESET_RANGES.map((pr) => {
                const active = tempMin === pr.min && tempMax === pr.max;
                return (
                  <button
                    key={pr.label}
                    onClick={() => pushPrice({ min: pr.min, max: pr.max })}
                    className={cn(
                      "rounded-lg border py-1 px-2 text-[10px] font-bold transition text-center",
                      active
                        ? "border-clay-500 bg-clay-50 text-clay-700"
                        : "border-sand-200 bg-sand-50/70 text-mute hover:border-sand-300 hover:text-ink"
                    )}
                  >
                    {pr.label}
                  </button>
                );
              })}
            </div>

            <p className="mt-3 text-[10px] text-mute">Lọc theo giá ngay khi kéo thanh.</p>
          </div>

          {/* Sort selection on Left */}
          <div className="pt-4 border-t border-sand-100">
            <p className="text-[11px] font-bold uppercase tracking-wider text-mute mb-2">
              Sắp xếp theo
            </p>
            <Dropdown
              value={sort}
              options={SORT_OPTIONS}
              onChange={onSort}
              icon={ArrowUpDown}
              active={sort !== "featured"}
              size="sm"
            />
          </div>
        </div>
      </aside>

      {/* ========================================================================= */}
      {/* 2. MOBILE STICKY LEFT RAIL (NẰM BÊN TRÁI VÀ ĐI THEO KHI CUỘN)            */}
      {/* ========================================================================= */}
      <aside className="lg:hidden w-[96px] sm:w-[110px] shrink-0 self-start sticky top-20 z-[800]">
        <div className="space-y-2 rounded-2xl border border-sand-200/90 bg-white/95 p-2 shadow-sm backdrop-blur-md">
          {/* Mobile Search Button */}
          <button
            onClick={() => setMobileSearchModal(true)}
            className={cn(
              "flex w-full flex-col items-center justify-center gap-1 rounded-xl p-2 text-center transition active:scale-95",
              search.trim()
                ? "bg-clay-500 text-white font-bold shadow-xs"
                : "bg-sand-50 text-ink hover:bg-sand-100"
            )}
          >
            <Search className="h-4 w-4" />
            <span className="text-[10px] font-bold uppercase tracking-wider leading-tight">
              {search.trim() ? "Đã tìm" : "Tìm kiếm"}
            </span>
          </button>

          {/* Mobile Categories Vertical List on Left */}
          <div className="space-y-1 pt-1 border-t border-sand-100">
            {categoryOptions.map((c) => {
              const active = category === c.id;
              const count = categoryCounts[c.id];
              return (
                <button
                  key={c.id}
                  onClick={() => onCategory(c.id)}
                  className={cn(
                    "flex w-full flex-col items-center justify-center rounded-xl py-2 px-1 text-center transition active:scale-95",
                    active
                      ? "bg-clay-500 text-white font-bold shadow-xs"
                      : "text-ink hover:bg-sand-100"
                  )}
                >
                  <span className="text-[10px] font-bold leading-tight line-clamp-1">{c.label}</span>
                  {count !== undefined && <span
                    className={cn(
                      "mt-0.5 rounded-full px-1.5 py-0.2 text-[9px]",
                      active ? "bg-white/25 text-white" : "bg-sand-100 text-mute"
                    )}
                  >
                    {count}
                  </span>}
                </button>
              );
            })}
          </div>

          {/* Mobile Price Filter Button on Left Rail */}
          <div className="pt-1 border-t border-sand-100 space-y-1">
            <button
              onClick={() => setMobilePriceModal(true)}
              className={cn(
                "flex w-full flex-col items-center justify-center gap-0.5 rounded-xl p-2 text-center transition active:scale-95",
                isCustomPrice
                  ? "bg-amber-600 text-white font-bold shadow-xs"
                  : "bg-sand-50 text-ink hover:bg-sand-100"
              )}
            >
              <Tag className="h-3.5 w-3.5" />
              <span className="text-[10px] font-bold uppercase leading-tight">Lọc giá</span>
              {isCustomPrice && (
                <span className="text-[8px] opacity-90 truncate max-w-[80px]">
                  {shortMoney(price.min)}-{shortMoney(price.max)}
                </span>
              )}
            </button>

            {/* Mobile Reset button on Left Rail if filtered */}
            {isFiltered && (
              <button
                onClick={resetAll}
                className="flex w-full items-center justify-center gap-1 rounded-xl bg-sand-100 py-1.5 text-[9px] font-bold text-clay-700 hover:bg-sand-200 transition"
              >
                <RotateCcw className="h-3 w-3" />
                <span>Đặt lại</span>
              </button>
            )}
          </div>
        </div>
      </aside>

      {/* ========================================================================= */}
      {/* 3. MOBILE SEARCH MODAL (NHANH, GỌN, KHÔNG BỊ NGỘP)                       */}
      {/* ========================================================================= */}
      <AnimatePresence>
        {mobileSearchModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[3200] lg:hidden flex items-start justify-center p-3 pt-20 bg-ink/60 backdrop-blur-xs"
            onClick={() => setMobileSearchModal(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: -20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -20, scale: 0.95 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-sm rounded-3xl bg-white p-4 shadow-2xl"
            >
              <div className="flex items-center justify-between pb-2.5 border-b border-sand-200">
                <span className="text-xs font-bold uppercase tracking-wider text-ink">Tìm kiếm sản phẩm</span>
                <button
                  onClick={() => setMobileSearchModal(false)}
                  className="flex h-7 w-7 items-center justify-center rounded-full text-mute hover:bg-sand-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="relative mt-3">
                <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-mute" />
                <input
                  autoFocus
                  type="text"
                  value={search}
                  onChange={(e) => onSearch(e.target.value)}
                  placeholder="Nhập tên áo, đầm, váy, quần..."
                  className="w-full rounded-2xl border border-sand-200 bg-sand-50 py-2.5 pl-10 pr-9 text-xs text-ink outline-none focus:border-clay-400 focus:bg-white"
                />
                {search && (
                  <button
                    onClick={() => onSearch("")}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-mute"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>

              {/* Suggestions */}
              <div className="mt-3">
                <p className="text-[10px] font-bold uppercase text-mute mb-1.5">Gợi ý:</p>
                <div className="flex flex-wrap gap-1.5">
                  {SUGGESTIONS.map((s) => (
                    <button
                      key={s}
                      onClick={() => {
                        onSearch(s);
                        setMobileSearchModal(false);
                      }}
                      className="rounded-lg border border-sand-200 bg-sand-50 px-2.5 py-1 text-[11px] font-medium text-ink"
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </div>

              <div className="mt-4 flex gap-2 pt-2 border-t border-sand-100">
                <button
                  onClick={() => setMobileSearchModal(false)}
                  className="w-full rounded-xl bg-ink py-2.5 text-xs font-bold uppercase tracking-wider text-white shadow"
                >
                  Xem kết quả ({resultCount})
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ========================================================================= */}
      {/* 4. MOBILE PRICE RANGE MODAL                                               */}
      {/* ========================================================================= */}
      <AnimatePresence>
        {mobilePriceModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[3200] lg:hidden flex items-end justify-center bg-ink/60 backdrop-blur-xs"
            onClick={() => setMobilePriceModal(false)}
          >
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", stiffness: 340, damping: 32 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md rounded-t-3xl bg-sand-50 p-5 shadow-2xl"
            >
              <div className="mx-auto mb-4 h-1.5 w-12 rounded-full bg-sand-300" />
              <div className="flex items-center justify-between pb-3 border-b border-sand-200">
                <div className="flex items-center gap-1.5">
                  <Tag className="h-4 w-4 text-clay-600" />
                  <h3 className="font-display text-base font-bold text-ink">Khoảng giá (VNĐ)</h3>
                </div>
                <button
                  onClick={() => setMobilePriceModal(false)}
                  className="flex h-7 w-7 items-center justify-center rounded-full text-mute hover:bg-sand-200"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="mt-3 flex items-center justify-between text-xs font-bold text-clay-600">
                <span>{formatMoney(tempMin)}</span>
                <span>{formatMoney(tempMax)}</span>
              </div>

              <div className="my-3">
                <DualRange
                  min={PRICE_MIN}
                  max={PRICE_MAX}
                  value={{ min: tempMin, max: tempMax }}
                  onChange={pushPrice}
                />
              </div>

              {/* Preset chips */}
              <div className="grid grid-cols-2 gap-1.5 mt-3">
                {PRESET_RANGES.map((pr) => (
                  <button
                    key={pr.label}
                    onClick={() => pushPrice({ min: pr.min, max: pr.max })}
                    className={cn(
                      "rounded-xl border py-1.5 px-2 text-[11px] font-bold text-center",
                      tempMin === pr.min && tempMax === pr.max
                        ? "border-clay-500 bg-clay-50 text-clay-700"
                        : "border-sand-200 bg-white text-mute"
                    )}
                  >
                    {pr.label}
                  </button>
                ))}
              </div>

              {/* Number Inputs */}
              <div className="mt-4 grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] font-bold uppercase text-mute block mb-0.5">Từ (VNĐ)</label>
                  <input
                    type="number"
                    step={10000}
                    min={PRICE_MIN}
                    max={tempMax - 10000}
                    value={tempMin}
                    onChange={(e) => {
                      const min = Number(e.target.value);
                      pushPrice({ min, max: tempMax });
                    }}
                    className="w-full rounded-xl border border-sand-200 bg-white px-2.5 py-1.5 text-xs font-bold text-ink outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold uppercase text-mute block mb-0.5">Đến (VNĐ)</label>
                  <input
                    type="number"
                    step={10000}
                    min={tempMin + 10000}
                    max={PRICE_MAX}
                    value={tempMax}
                    onChange={(e) => {
                      const max = Number(e.target.value);
                      pushPrice({ min: tempMin, max });
                    }}
                    className="w-full rounded-xl border border-sand-200 bg-white px-2.5 py-1.5 text-xs font-bold text-ink outline-none"
                  />
                </div>
              </div>

              <div className="mt-5 flex gap-2 pt-3 border-t border-sand-200">
                <button
                  onClick={resetPrice}
                  className="flex-1 rounded-xl border border-sand-300 bg-white py-2.5 text-xs font-bold text-mute"
                >
                  Mặc định
                </button>
                <button
                  onClick={() => setMobilePriceModal(false)}
                  className="flex-1 rounded-xl bg-clay-500 py-2.5 text-xs font-bold uppercase tracking-wider text-white shadow"
                >
                  Xong
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
