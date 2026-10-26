import { api, type PageResponse } from "@/lib/api";
import type { CartItem, OrderRecord } from "@/context/CartContext";
import { mapOrder, toApiPaymentMethod } from "./mappers";
import type {
  CreateOrderRequest,
  OrderItemRequest,
  OrderResponse,
  OrderSummaryResponse,
  ProductSize,
} from "./types";

export interface PlaceOrderInput {
  customerName: string;
  phone: string;
  email?: string;
  address: string;
  note?: string;
  paymentMethod: OrderRecord["paymentMethod"];
  items: CartItem[];
}

export async function placeOrder(input: PlaceOrderInput): Promise<OrderRecord> {
  const items: OrderItemRequest[] = input.items.map((item) => ({
    productId: item.id,
    size: item.size.toUpperCase() as ProductSize,
    quantity: item.qty,
  }));

  const body: CreateOrderRequest = {
    receiverName: input.customerName.trim(),
    phone: input.phone.trim(),
    email: input.email?.trim() || undefined,
    address: input.address.trim(),
    note: input.note?.trim() || undefined,
    paymentMethod: toApiPaymentMethod(input.paymentMethod),
    items,
  };

  const result = await api.post<OrderResponse>("/orders", body);
  return mapOrder(result);
}

export async function fetchMyOrders(page = 0, size = 50): Promise<OrderRecord[]> {
  const result = await api.get<PageResponse<OrderSummaryResponse>>("/orders/me", {
    page,
    size,
    sort: "createdAt,desc",
  });

  return result.content.map((dto) => ({
    orderNumber: dto.orderNumber,
    customerName: dto.receiverName,
    phone: "",
    address: "",
    paymentMethod: dto.paymentMethod === "BANK_TRANSFER" ? "qr" : "cod",
    status:
      dto.status === "PENDING"
        ? "pending"
        : dto.status === "CONFIRMED"
          ? "confirmed"
          : dto.status === "SHIPPING"
            ? "shipping"
            : dto.status === "COMPLETED"
              ? "completed"
              : "cancelled",
    subtotal: dto.total,
    shippingFee: 0,
    discount: 0,
    total: dto.total,
    items: [],
    createdAt: dto.createdAt,
  }));
}

export async function fetchMyOrderByNumber(orderNumber: string): Promise<OrderRecord> {
  const result = await api.get<OrderResponse>(
    `/orders/me/${encodeURIComponent(orderNumber.trim().toUpperCase())}`
  );
  return mapOrder(result);
}

export async function cancelMyOrder(orderNumber: string, reason?: string): Promise<OrderRecord> {
  const result = await api.post<OrderResponse>(
    `/orders/me/${encodeURIComponent(orderNumber.trim().toUpperCase())}/cancel`,
    reason?.trim() ? { reason: reason.trim() } : undefined
  );
  return mapOrder(result);
}
