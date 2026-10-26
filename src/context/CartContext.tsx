"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import type { ReactNode } from "react";
import type { Product } from "@/data/products";

export interface CartItem {
  id: string;
  name: string;
  price: number;
  img: string;
  size: string;
  qty: number;
}

export interface OrderRecord {
  orderNumber: string;
  customerName: string;
  phone: string;
  email?: string;
  address: string;
  note?: string;
  paymentMethod: "cod" | "qr";
  status: "pending" | "confirmed" | "shipping" | "completed" | "cancelled";
  subtotal: number;
  shippingFee: number;
  discount: number;
  total: number;
  items: CartItem[];
  createdAt: string;
  cancelReason?: string;
}

interface CartContextValue {
  items: CartItem[];
  count: number;
  subtotal: number;
  addItem: (product: Product, size: string, qty?: number) => void;
  addMultipleItems: (product: Product, sizeSelection: Record<string, number>) => void;
  mergeItems: (incoming: CartItem[]) => void;
  updateQty: (id: string, size: string, qty: number) => void;
  removeItem: (id: string, size: string) => void;
  removeMany: (keys: Array<{ id: string; size: string }>) => void;
  clear: () => void;
  wishlist: string[];
  toggleWishlist: (id: string) => void;
  isWished: (id: string) => boolean;
  orders: OrderRecord[];
  rememberOrder: (order: OrderRecord) => void;
  lookupOrder: (codeOrPhone: string) => OrderRecord | null;
}

const CartContext = createContext<CartContextValue | null>(null);

const CART_KEY = "la-boutique-cart-v4";
const WISH_KEY = "la-boutique-wish-v4";
const ORDERS_KEY = "la-boutique-orders-v4";

function loadFromStorage<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  const [wishlist, setWishlist] = useState<string[]>([]);
  const [orders, setOrders] = useState<OrderRecord[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setItems(loadFromStorage<CartItem[]>(CART_KEY, []));
    setWishlist(loadFromStorage<string[]>(WISH_KEY, []));
    setOrders(loadFromStorage<OrderRecord[]>(ORDERS_KEY, []));
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (hydrated) {
      localStorage.setItem(CART_KEY, JSON.stringify(items));
    }
  }, [items, hydrated]);

  useEffect(() => {
    if (hydrated) {
      localStorage.setItem(WISH_KEY, JSON.stringify(wishlist));
    }
  }, [wishlist, hydrated]);

  useEffect(() => {
    if (hydrated) {
      localStorage.setItem(ORDERS_KEY, JSON.stringify(orders));
    }
  }, [orders, hydrated]);

  const addItem = useCallback((product: Product, size: string, qty = 1) => {
    if (qty <= 0) return;
    setItems((prev) => {
      const idx = prev.findIndex((it) => it.id === product.id && it.size === size);
      if (idx >= 0) {
        const next = [...prev];
        next[idx] = { ...next[idx], qty: next[idx].qty + qty };
        return next;
      }
      return [
        ...prev,
        {
          id: product.id,
          name: product.name,
          price: product.price,
          img: product.img,
          size,
          qty,
        },
      ];
    });
  }, []);

  const addMultipleItems = useCallback(
    (product: Product, sizeSelection: Record<string, number>) => {
      setItems((prev) => {
        const next = [...prev];
        Object.entries(sizeSelection).forEach(([size, qty]) => {
          if (qty <= 0) return;
          const idx = next.findIndex((it) => it.id === product.id && it.size === size);
          if (idx >= 0) {
            next[idx] = { ...next[idx], qty: next[idx].qty + qty };
          } else {
            next.push({
              id: product.id,
              name: product.name,
              price: product.price,
              img: product.img,
              size,
              qty,
            });
          }
        });
        return next;
      });
    },
    []
  );

  const mergeItems = useCallback((incoming: CartItem[]) => {
    if (!incoming.length) return;
    setItems((prev) => {
      const next = [...prev];
      incoming.forEach((it) => {
        if (it.qty <= 0) return;
        const idx = next.findIndex((row) => row.id === it.id && row.size === it.size);
        if (idx >= 0) {
          next[idx] = { ...next[idx], qty: next[idx].qty + it.qty };
        } else {
          next.push({ ...it });
        }
      });
      return next;
    });
  }, []);

  const updateQty = useCallback((id: string, size: string, qty: number) => {
    if (qty <= 0) {
      setItems((prev) => prev.filter((it) => !(it.id === id && it.size === size)));
      return;
    }
    setItems((prev) =>
      prev.map((it) => (it.id === id && it.size === size ? { ...it, qty } : it))
    );
  }, []);

  const removeItem = useCallback((id: string, size: string) => {
    setItems((prev) => prev.filter((it) => !(it.id === id && it.size === size)));
  }, []);

  const removeMany = useCallback((keys: Array<{ id: string; size: string }>) => {
    if (!keys.length) return;
    setItems((prev) =>
      prev.filter((it) => !keys.some((k) => k.id === it.id && k.size === it.size))
    );
  }, []);

  const clear = useCallback(() => {
    setItems([]);
  }, []);

  const toggleWishlist = useCallback((id: string) => {
    setWishlist((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  }, []);

  const isWished = useCallback((id: string) => wishlist.includes(id), [wishlist]);

  const rememberOrder = useCallback((order: OrderRecord) => {
    setOrders((prev) => {
      const rest = prev.filter((o) => o.orderNumber !== order.orderNumber);
      return [order, ...rest];
    });
  }, []);

  const lookupOrder = useCallback(
    (codeOrPhone: string): OrderRecord | null => {
      const q = codeOrPhone.trim().toLowerCase();
      if (!q) return null;
      return (
        orders.find(
          (o) =>
            o.orderNumber.toLowerCase() === q ||
            o.phone.replace(/\s+/g, "").includes(q.replace(/\s+/g, ""))
        ) ?? null
      );
    },
    [orders]
  );

  const count = useMemo(() => items.reduce((s, it) => s + it.qty, 0), [items]);
  const subtotal = useMemo(() => items.reduce((s, it) => s + it.price * it.qty, 0), [items]);

  return (
    <CartContext.Provider
      value={{
        items,
        count,
        subtotal,
        addItem,
        addMultipleItems,
        mergeItems,
        updateQty,
        removeItem,
        removeMany,
        clear,
        wishlist,
        toggleWishlist,
        isWished,
        orders,
        rememberOrder,
        lookupOrder,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within CartProvider");
  return ctx;
}
