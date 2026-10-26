import { AnimatePresence } from "framer-motion";
import { useLayoutEffect } from "react";
import { Navigate, Outlet, Route, Routes, matchPath, useLocation, useNavigate } from "react-router-dom";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { CartDrawer } from "@/components/CartDrawer";
import { WishlistDrawer } from "@/components/WishlistDrawer";
import { CategorySheet } from "@/components/CategorySheet";
import { SizeGuideModal } from "@/components/SizeGuideModal";
import { CheckoutModal } from "@/components/CheckoutModal";
import { SuccessModal } from "@/components/SuccessModal";
import { BottomNav } from "@/components/BottomNav";
import { CartProvider, useCart, type CartItem, type OrderRecord } from "@/context/CartContext";
import { AuthProvider } from "@/context/AuthContext";
import { AdminLayout } from "@/pages/admin/AdminLayout";
import { AdminAccountsPage } from "@/pages/admin/AdminAccountsPage";
import { AdminCategoriesPage } from "@/pages/admin/AdminCategoriesPage";
import { AdminCollectionsPage } from "@/pages/admin/AdminCollectionsPage";
import { AdminOrdersPage } from "@/pages/admin/AdminOrdersPage";
import { AdminProductsPage } from "@/pages/admin/AdminProductsPage";
import { AdminRolesPage } from "@/pages/admin/AdminRolesPage";
import { CatalogProvider } from "@/context/CatalogContext";
import { ToastProvider } from "@/context/ToastContext";
import type { CheckoutIntent, ShopOutletContext } from "@/context/ShopOutlet";
import { useScrollLock } from "@/hooks/useScrollLock";
import { paths } from "@/lib/paths";
import { HomePage } from "@/pages/HomePage";
import { CatalogPage } from "@/pages/CatalogPage";
import { ProductPage } from "@/pages/ProductPage";
import { PolicyPage } from "@/pages/PolicyPage";
import { OrderLookupModal } from "@/components/OrderLookupModal";
import { useEffect, useState } from "react";
import type { Product } from "@/data/products";

function ScrollToTop() {
  const { pathname, hash } = useLocation();
  useLayoutEffect(() => {
    if (hash) return;
    if (pathname.startsWith("/san-pham/")) return;
    window.scrollTo(0, 0);
  }, [pathname, hash]);
  return null;
}

function ShopLayout() {
  const { count, wishlist, removeMany } = useCart();
  const location = useLocation();
  const navigate = useNavigate();

  const [cartOpen, setCartOpen] = useState(false);
  const [wishlistOpen, setWishlistOpen] = useState(false);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [successOpen, setSuccessOpen] = useState(false);
  const [lastOrder, setLastOrder] = useState<OrderRecord | null>(null);
  const [sizeGuideOpen, setSizeGuideOpen] = useState(false);
  const [lookupOpen, setLookupOpen] = useState(false);
  const [lookupCode, setLookupCode] = useState("");
  const [directCheckout, setDirectCheckout] = useState<CartItem[] | null>(null);
  const [checkoutIntent, setCheckoutIntent] = useState<CheckoutIntent>("cart");

  const openLookup = (code = "") => {
    setLookupCode(code);
    setLookupOpen(true);
  };

  useEffect(() => {
    if (location.pathname !== "/tra-cuu") return;
    const ma = new URLSearchParams(location.search).get("ma") || "";
    openLookup(ma);
    navigate("/", { replace: true });
  }, [location.pathname, location.search, navigate]);

  const isProduct = !!matchPath("/san-pham/:slug", location.pathname);
  const overlayOpen =
    isProduct ||
    cartOpen ||
    wishlistOpen ||
    sheetOpen ||
    checkoutOpen ||
    successOpen ||
    sizeGuideOpen ||
    lookupOpen;

  useScrollLock(overlayOpen);

  const outletContext: ShopOutletContext = {
    openCart: () => setCartOpen(true),
    openCheckout: (directItems?: CartItem[], intent: CheckoutIntent = "buynow") => {
      setCartOpen(false);
      setDirectCheckout(directItems ?? null);
      setCheckoutIntent(directItems ? intent : "cart");
      setCheckoutOpen(true);
    },
    openSizeGuide: () => setSizeGuideOpen(true),
  };

  const handleCheckoutSuccess = (order: OrderRecord) => {
    setCheckoutOpen(false);
    setLastOrder(order);
    setSuccessOpen(true);
  };

  const selectCategory = (cat: string) => {
    setSheetOpen(false);
    navigate(paths.catalog(cat));
  };

  return (
    <div className="min-h-screen bg-sand-50" id="top">
      <Header
        onOpenCart={() => setCartOpen(true)}
        onOpenWishlist={() => setWishlistOpen(true)}
        onOpenLookup={() => openLookup()}
        forceSolid={location.pathname !== "/"}
      />

      <main>
        <Outlet context={outletContext} />
      </main>

      {!isProduct && <Footer onOpenLookup={() => openLookup()} />}

      <BottomNav
        onShop={() => setSheetOpen(true)}
        onWishlist={() => setWishlistOpen(true)}
        onCart={() => setCartOpen(true)}
        onOrderLookup={() => openLookup()}
        cartCount={count}
        wishCount={wishlist.length}
        hidden={overlayOpen}
      />

      <AnimatePresence>
        {cartOpen && (
          <CartDrawer
            onClose={() => setCartOpen(false)}
            onCheckout={(picked) => {
              setCartOpen(false);
              setDirectCheckout(picked);
              setCheckoutIntent("cart");
              setCheckoutOpen(true);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {wishlistOpen && (
          <WishlistDrawer
            onClose={() => setWishlistOpen(false)}
            onOpenProduct={(p: Product) => {
              setWishlistOpen(false);
              navigate(paths.product(p.slug), {
                state: { from: location.pathname + location.search },
              });
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {sheetOpen && (
          <CategorySheet
            onClose={() => setSheetOpen(false)}
            onSelect={selectCategory}
            current={
              matchPath("/bo-suu-tap/:category", location.pathname)?.params.category ||
              (location.pathname === "/bo-suu-tap" ? "all" : "")
            }
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {sizeGuideOpen && <SizeGuideModal onClose={() => setSizeGuideOpen(false)} />}
      </AnimatePresence>

      <AnimatePresence>
        {checkoutOpen && (
          <CheckoutModal
            itemsOverride={directCheckout}
            intent={directCheckout ? checkoutIntent : "cart"}
            onClose={() => {
              setCheckoutOpen(false);
              setDirectCheckout(null);
            }}
            onSuccess={(order) => {
              if (checkoutIntent === "cart" && directCheckout?.length) {
                removeMany(directCheckout.map((it) => ({ id: it.id, size: it.size })));
              }
              setDirectCheckout(null);
              handleCheckoutSuccess(order);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {successOpen && (
          <SuccessModal
            orderData={lastOrder}
            onClose={() => setSuccessOpen(false)}
            onTrackOrder={(code) => {
              setSuccessOpen(false);
              openLookup(code);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {lookupOpen && (
          <OrderLookupModal
            key={lookupCode || "lookup"}
            initialCode={lookupCode}
            onClose={() => {
              setLookupOpen(false);
              setLookupCode("");
            }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

function ShopApp() {
  return (
    <>
      <ScrollToTop />
      <Routes>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Navigate to="/admin/don-hang" replace />} />
          <Route path="don-hang" element={<AdminOrdersPage />} />
          <Route path="san-pham" element={<AdminProductsPage />} />
          <Route path="danh-muc" element={<AdminCategoriesPage />} />
          <Route path="bo-suu-tap" element={<AdminCollectionsPage />} />
          <Route path="tai-khoan" element={<AdminAccountsPage />} />
          <Route path="role" element={<AdminRolesPage />} />
        </Route>

        <Route element={<ShopLayout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/bo-suu-tap" element={<CatalogPage />} />
          <Route path="/bo-suu-tap/:category" element={<CatalogPage />} />
          <Route path="/san-pham/:slug" element={<ProductPage />} />
          <Route path="/tra-cuu" element={<HomePage />} />
          <Route path="/chinh-sach/:slug" element={<PolicyPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <CatalogProvider>
        <CartProvider>
          <ToastProvider>
            <ShopApp />
          </ToastProvider>
        </CartProvider>
      </CatalogProvider>
    </AuthProvider>
  );
}
