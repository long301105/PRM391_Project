import { ArrowRight } from "lucide-react";
import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Hero } from "@/components/Hero";
import { ValueStrip } from "@/components/ValueStrip";
import { ProductCard } from "@/components/ProductCard";
import { Marquee } from "@/components/Marquee";
import { BrandStory } from "@/components/BrandStory";
import { ReviewsBoard } from "@/components/ReviewsBoard";
import { useCatalog } from "@/context/CatalogContext";
import type { Product } from "@/data/products";
import { paths } from "@/lib/paths";
import { scrollToId } from "@/lib/scroll";
import { cn } from "@/utils/cn";

export function HomePage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { products } = useCatalog();

  const homeSunsetSets: Product[] = products.filter((p) => p.isSummer).slice(0, 3);

  const homeAoItems = products.filter((p) => p.type === "ao" && !p.isSummer).slice(0, 8);
  const homeQuanItems = products.filter((p) => p.type === "quan").slice(0, 6);

  const openProduct = (p: Product) => {
    navigate(paths.product(p.slug), { state: { from: location.pathname + location.search } });
  };

  useEffect(() => {
    if (location.hash === "#story") {
      const t = window.setTimeout(() => scrollToId("story"), 80);
      return () => window.clearTimeout(t);
    }
    return undefined;
  }, [location.hash]);

  return (
    <>
      <Hero onExplore={() => navigate(paths.catalog("all"))} />
      <ValueStrip />

      <section id="summer" className="scroll-mt-[80px] px-3.5 py-10 sm:px-6 sm:py-16 bg-sand-50">
        <div className="mx-auto max-w-6xl">
          <div className="mb-7 sm:mb-10 text-center px-2">
            <p className="mb-1.5 text-[10px] sm:text-[11px] font-bold uppercase tracking-[0.25em] text-clay-500">
              Bộ sưu tập biểu tượng · Hè 2026
            </p>
            <h2 className="font-display text-2xl sm:text-3xl md:text-4xl font-bold text-ink">
              La Boutique VN Sunset Collection
            </h2>
            <p className="mx-auto mt-2 max-w-xl text-xs sm:text-sm leading-relaxed text-mute">
              Nổi bật với 3 set thiết kế độc quyền cao cấp: Set SS 26-1, Set Sunset và Set SS 26-2. Sắc màu hoàng hôn lãng mạn cùng phom dáng bay bổng quyến rũ.
            </p>
          </div>

          <div className="mx-auto grid grid-cols-2 md:grid-cols-3 gap-3 sm:gap-6 max-w-5xl items-stretch justify-center">
            <div className="w-full flex flex-col">
              <ProductCard product={homeSunsetSets[0]} index={0} onOpen={openProduct} />
            </div>
            <div className="w-full flex flex-col">
              <ProductCard product={homeSunsetSets[1]} index={1} onOpen={openProduct} />
            </div>
            <div className="w-full col-span-2 md:col-span-1 max-w-[280px] md:max-w-none mx-auto flex flex-col">
              <ProductCard product={homeSunsetSets[2]} index={2} onOpen={openProduct} />
            </div>
          </div>

          <div className="mt-8 sm:mt-10 text-center">
            <button
              onClick={() => navigate(paths.catalog("sunset"))}
              className="inline-flex items-center gap-2 rounded-full border-2 border-ink bg-white px-6 py-2.5 sm:px-8 sm:py-3 text-xs font-bold uppercase tracking-wider text-ink shadow-xs transition hover:bg-ink hover:text-white active:scale-95"
            >
              <span>Khám phá bộ sưu tập Sunset</span>
              <ArrowRight className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
            </button>
          </div>
        </div>
      </section>

      <Marquee />

      <section id="ao" className="scroll-mt-[80px] px-3.5 py-10 sm:px-6 sm:py-16 bg-white">
        <div className="mx-auto max-w-6xl">
          <div className="mb-7 sm:mb-10 text-center px-2">
            <p className="mb-1.5 text-[10px] sm:text-[11px] font-bold uppercase tracking-[0.25em] text-clay-500">
              Tủ đồ mùa hè
            </p>
            <h2 className="font-display text-2xl sm:text-3xl md:text-4xl font-bold text-ink">
              Áo Cổ Yếm, Áo Xô & Đầm Lụa
            </h2>
            <p className="mx-auto mt-2 max-w-xl text-xs sm:text-sm leading-relaxed text-mute">
              Chất liệu tơ xốp, xô muslin và lụa mềm mịn ôm dáng, tôn vinh nét đẹp thanh thoát của người phụ nữ.
            </p>
          </div>

          <div className="hidden md:block">
            <div className="mx-auto grid grid-cols-3 gap-6 max-w-5xl justify-center">
              {homeAoItems.slice(0, 3).map((p, i) => (
                <div key={p.id} className="w-full flex flex-col">
                  <ProductCard product={p} index={i} onOpen={openProduct} />
                </div>
              ))}
            </div>
            <div className="mt-6 mx-auto grid grid-cols-2 gap-6 max-w-2xl justify-center">
              {homeAoItems.slice(3, 5).map((p, i) => (
                <div key={p.id} className="w-full flex flex-col">
                  <ProductCard product={p} index={i + 3} onOpen={openProduct} />
                </div>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 md:hidden">
            {homeAoItems.map((p, i) => (
              <div
                key={p.id}
                className={cn("w-full flex flex-col", i === 4 && "col-span-2 max-w-[200px] mx-auto")}
              >
                <ProductCard product={p} index={i} onOpen={openProduct} />
              </div>
            ))}
          </div>

          <div className="mt-8 sm:mt-10 text-center">
            <button
              onClick={() => navigate(paths.catalog("ao"))}
              className="inline-flex items-center gap-2 rounded-full border-2 border-ink bg-white px-6 py-2.5 sm:px-8 sm:py-3 text-xs font-bold uppercase tracking-wider text-ink shadow-xs transition hover:bg-ink hover:text-white active:scale-95"
            >
              <span>Khám phá thêm Áo & Đầm</span>
              <ArrowRight className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
            </button>
          </div>
        </div>
      </section>

      <Marquee />

      <section id="quan" className="scroll-mt-[80px] px-3.5 py-10 sm:px-6 sm:py-16 bg-sand-50">
        <div className="mx-auto max-w-5xl">
          <div className="mb-7 sm:mb-10 text-center px-2">
            <p className="mb-1.5 text-[10px] sm:text-[11px] font-bold uppercase tracking-[0.25em] text-clay-500">
              Phóng khoáng & Tiện dụng
            </p>
            <h2 className="font-display text-2xl sm:text-3xl md:text-4xl font-bold text-ink">
              Quần & Chân Váy Nữ
            </h2>
            <p className="mx-auto mt-2 max-w-xl text-xs sm:text-sm leading-relaxed text-mute">
              Chân váy lụa lửng mềm mại và váy dệt kim xốp cao cấp cho nàng thoả sức biến tấu phong cách du ngoạn.
            </p>
          </div>

          <div className="mx-auto grid grid-cols-2 gap-3 sm:gap-6 max-w-2xl justify-center">
            {homeQuanItems.map((p, i) => (
              <div key={p.id} className="w-full flex flex-col">
                <ProductCard product={p} index={i} onOpen={openProduct} />
              </div>
            ))}
          </div>

          <div className="mt-8 sm:mt-10 text-center">
            <button
              onClick={() => navigate(paths.catalog("quan"))}
              className="inline-flex items-center gap-2 rounded-full border-2 border-ink bg-white px-6 py-2.5 sm:px-8 sm:py-3 text-xs font-bold uppercase tracking-wider text-ink shadow-xs transition hover:bg-ink hover:text-white active:scale-95"
            >
              <span>Khám phá thêm Quần & Váy</span>
              <ArrowRight className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
            </button>
          </div>
        </div>
      </section>

      <div className="py-10 sm:py-14 bg-sand-100/60 border-y border-sand-200 text-center px-4">
        <div className="max-w-2xl mx-auto">
          <p className="text-[10px] sm:text-xs font-bold uppercase tracking-[0.25em] text-clay-600 mb-1.5">
            Khám phá toàn bộ
          </p>
          <h3 className="font-display text-2xl sm:text-3xl font-bold text-ink mb-2">
            Toàn Bộ 18 Thiết Kế Mùa Hè 2026
          </h3>
          <p className="text-xs text-mute mb-5 max-w-md mx-auto leading-relaxed">
            Xem đầy đủ các bộ trang phục, áo cổ yếm, áo xô, đầm lụa, chân váy và quần ống suông của LA BOUTIQUE VN.
          </p>
          <button
            onClick={() => navigate(paths.catalog("all"))}
            className="inline-flex items-center gap-2 rounded-full bg-ink px-7 py-3 sm:px-9 sm:py-3.5 text-xs font-bold uppercase tracking-wider text-white shadow-lg hover:bg-clay-600 transition active:scale-95"
          >
            <span>Khám phá tất cả sản phẩm ({products.length})</span>
            <ArrowRight className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
          </button>
        </div>
      </div>

      <section id="reviews" className="scroll-mt-[80px] px-3.5 py-10 sm:px-6 sm:py-16 bg-white">
        <div className="mx-auto max-w-6xl">
          <ReviewsBoard />
        </div>
      </section>

      <BrandStory />
    </>
  );
}
