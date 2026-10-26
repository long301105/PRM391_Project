
export type Category = "ao" | "quan";
export type CollectionType = "sunset" | "regular";

export interface Product {
  id: string;
  name: string;
  slug: string;
  price: number;
  originalPrice?: number;
  type: Category;
  isSummer: boolean;
  isFeatured?: boolean;
  collection: CollectionType;
  img: string;
  gallery: string[];
  tag?: string;
  description?: string;
  material?: string;
  careInstructions?: string;
  createdAt?: string;
  variants?: Array<{ size: string; stockQuantity: number }>;
}

export const SIZES = ["S", "M", "L"] as const;

export const PRICE_MIN = 200000;
export const PRICE_MAX = 800000;

export const GALLERY_EXTRA: string[] = [
  "/images/products/sunset-main-1.jpg",
  "/images/products/ss26-1-1.jpg",
  "/images/products/ss26-2-1.jpg",
];
