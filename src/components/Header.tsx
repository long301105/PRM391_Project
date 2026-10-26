"use client";

import { motion } from "framer-motion";
import { Heart, ShoppingBag, Truck } from "lucide-react";
import { useEffect, useState, type MouseEvent as ReactMouseEvent } from "react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { useCart } from "@/context/CartContext";
import { IconToast } from "@/context/ToastContext";
import { paths } from "@/lib/paths";
import { scrollToId } from "@/lib/scroll";
import { cn } from "@/utils/cn";

interface HeaderProps {
  onOpenCart: () => void;
  onOpenWishlist: () => void;
  onOpenLookup: () => void;
  forceSolid?: boolean;
}

const NAV = [
  { label: "Sunset", to: paths.catalog("sunset"), match: "/bo-suu-tap/sunset" },
  { label: "Áo & Đầm", to: paths.catalog("ao"), match: "/bo-suu-tap/ao" },
  { label: "Quần & Váy", to: paths.catalog("quan"), match: "/bo-suu-tap/quan" },
];

export function Header({ onOpenCart, onOpenWishlist, onOpenLookup, forceSolid = false }: HeaderProps) {
  const { isAdmin } = useAuth();
  const { count, wishlist } = useCart();
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const isSolid = forceSolid || scrolled;
  const light = !isSolid;

  const goStory = (e: ReactMouseEvent<HTMLAnchorElement>) => {
    if (location.pathname === "/") {
      e.preventDefault();
      scrollToId("story");
    }
  };

  return (
    <header className="fixed inset-x-0 top-0 z-[1000]">
      <div
        className={cn(
          "h-16 transition-all duration-300",
          isSolid
            ? "border-b border-sand-200 bg-sand-50/95 shadow-sm backdrop-blur-md"
            : "border-b border-transparent bg-transparent shadow-none backdrop-blur-none"
        )}
      >
        <div
          className={cn(
            "relative mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 transition-colors duration-300 sm:px-6",
            light ? "text-white" : "text-ink"
          )}
        >
          <Link
            to={paths.home}
            className="flex shrink-0 items-center gap-1.5 text-left font-display text-[19px] font-bold leading-none tracking-[0.14em] transition-opacity hover:opacity-80 sm:text-[21px]"
          >
            <span>LA BOUTIQUE</span>
            <span className={light ? "text-amber-300 font-black" : "text-clay-500 font-black"}>VN</span>
          </Link>

          <nav className="absolute left-1/2 hidden -translate-x-1/2 items-center gap-6 lg:flex">
            {NAV.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  cn(
                    "text-[11px] font-bold uppercase tracking-[0.16em] transition",
                    light ? "text-white/80 hover:text-white" : "text-ink/65 hover:text-ink",
                    isActive && (light ? "text-amber-200" : "text-clay-600")
                  )
                }
              >
                {item.label}
              </NavLink>
            ))}
            <Link
              to={paths.story}
              onClick={goStory}
              className={cn(
                "text-[11px] font-bold uppercase tracking-[0.16em] transition",
                light ? "text-white/80 hover:text-white" : "text-ink/65 hover:text-ink"
              )}
            >
              Câu chuyện
            </Link>
          </nav>

          <div className="flex items-center gap-1 sm:gap-2">
            {isAdmin && (
              <Link
                to="/admin"
                className={cn(
                  "mr-1 hidden rounded-full px-3 py-1.5 text-[10.5px] font-bold uppercase tracking-wider transition md:inline-block",
                  light
                    ? "bg-white/20 text-white hover:bg-white/30"
                    : "bg-ink text-white hover:bg-clay-600"
                )}
              >
                Quản trị
              </Link>
            )}

            <button
              onClick={onOpenLookup}
              aria-label="Tra cứu đơn hàng"
              title="Tra cứu đơn hàng"
              className={cn(
                "relative hidden h-10 w-10 items-center justify-center rounded-full transition active:scale-95 md:flex",
                light ? "hover:bg-white/20" : "hover:bg-sand-200"
              )}
            >
              <Truck className="h-5 w-5" strokeWidth={1.8} />
            </button>

            <button
              onClick={onOpenWishlist}
              aria-label="Yêu thích"
              title="Danh sách yêu thích"
              className={cn(
                "relative flex h-10 w-10 items-center justify-center rounded-full transition active:scale-95",
                light ? "hover:bg-white/20" : "hover:bg-sand-200"
              )}
            >
              <Heart className="h-5 w-5" strokeWidth={1.8} />
              {wishlist.length > 0 && (
                <span className="absolute -right-0.5 -top-0.5 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-clay-500 px-1 text-[10px] font-bold text-white ring-2 ring-sand-50">
                  {wishlist.length}
                </span>
              )}
              {!location.pathname.startsWith("/san-pham/") && <IconToast anchor="wishlist" />}
            </button>

            <button
              onClick={onOpenCart}
              aria-label="Giỏ hàng"
              title="Giỏ hàng"
              className={cn(
                "relative flex h-10 w-10 items-center justify-center rounded-full transition active:scale-95",
                light ? "hover:bg-white/20" : "hover:bg-sand-200"
              )}
            >
              <ShoppingBag className="h-5 w-5" strokeWidth={1.8} />
              {count > 0 && (
                <motion.span
                  key={count}
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: "spring", stiffness: 500, damping: 22 }}
                  className={cn(
                    "absolute -right-0.5 -top-0.5 flex h-[19px] min-w-[19px] items-center justify-center rounded-full bg-clay-500 px-1 text-[10px] font-bold text-white ring-2",
                    light ? "ring-white/40" : "ring-sand-50"
                  )}
                >
                  {count}
                </motion.span>
              )}
              {!location.pathname.startsWith("/san-pham/") && <IconToast anchor="cart" />}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
