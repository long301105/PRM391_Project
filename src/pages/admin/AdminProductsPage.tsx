import { useCallback, useEffect, useMemo, useState } from "react";
import { adminCategories, adminProducts, type ProductWriteBody } from "@/api/admin";
import type {
  CategoryResponse,
  ProductDetailResponse,
  ProductResponse,
  ProductSize,
  RecordStatus,
} from "@/api/types";
import { formatMoney } from "@/lib/format";
import {
  AdminErrorBar,
  AdminModal,
  AdminNotice,
  CheckboxField,
  ConfirmButton,
  Field,
  GhostButton,
  Pager,
  PrimaryButton,
  SelectField,
  StatusBadge,
  TableShell,
  Td,
  Th,
  errorMessage,
} from "@/components/admin/ui";

const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const ALL_SIZES: ProductSize[] = ["S", "M", "L"];

const STATUS_LABEL: Record<RecordStatus, string> = {
  ACTIVE: "Đang bán",
  HIDDEN: "Đang ẩn",
  DELETED: "Đã xoá",
};

interface FormState {
  name: string;
  slug: string;
  sku: string;
  price: string;
  originalPrice: string;
  description: string;
  material: string;
  careInstructions: string;
  tag: string;
  categoryId: string;
  status: RecordStatus;
  isSummer: boolean;
  isFeatured: boolean;
}

const EMPTY_FORM: FormState = {
  name: "",
  slug: "",
  sku: "",
  price: "",
  originalPrice: "",
  description: "",
  material: "",
  careInstructions: "",
  tag: "",
  categoryId: "",
  status: "ACTIVE",
  isSummer: false,
  isFeatured: false,
};

export function AdminProductsPage() {
  const [products, setProducts] = useState<ProductResponse[]>([]);
  const [categories, setCategories] = useState<CategoryResponse[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const [formOpen, setFormOpen] = useState(false);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [current, setCurrent] = useState<ProductDetailResponse | null>(null);

  const load = useCallback(async (target = 0) => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminProducts.list({ page: target, size: 20 });
      setProducts(result.content);
      setPage(result.page);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch (err) {
      setError(errorMessage(err, "Không tải được danh sách sản phẩm."));
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    void load(0);
    adminCategories
      .list({ size: 100 })
      .then((result) => setCategories(result.content.filter((c) => c.status !== "DELETED")))
      .catch(() => setCategories([]));
  }, [load]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return products;
    return products.filter(
      (product) =>
        product.name.toLowerCase().includes(q) || product.sku.toLowerCase().includes(q)
    );
  }, [products, query]);

  const categoryOptions = categories.map((c) => ({ value: c.id, label: c.categoryName }));

  const openCreate = () => {
    setForm({ ...EMPTY_FORM, categoryId: categories[0]?.id ?? "" });
    setCurrent(null);
    setFormOpen(true);
  };

  const openEdit = async (product: ProductResponse) => {
    setBusy(true);
    setError(null);
    try {
      const detail = await adminProducts.get(product.id);
      setCurrent(detail);
      setForm({
        name: detail.name,
        slug: detail.slug,
        sku: detail.sku,
        price: String(detail.price),
        originalPrice: detail.originalPrice != null ? String(detail.originalPrice) : "",
        description: detail.description ?? "",
        material: detail.material ?? "",
        careInstructions: detail.careInstructions ?? "",
        tag: detail.tag ?? "",
        categoryId: detail.categoryId ?? "",
        status: detail.status,
        isSummer: detail.isSummer ?? false,
        isFeatured: detail.isFeatured ?? false,
      });
      setFormOpen(true);
    } catch (err) {
      setError(errorMessage(err, "Không tải được sản phẩm."));
    } finally {
      setBusy(false);
    }
  };

  const closeForm = () => {
    setFormOpen(false);
    setCurrent(null);
  };

  const applyDetail = (detail: ProductDetailResponse) => {
    setCurrent(detail);
    setForm((prev) => ({ ...prev, status: detail.status }));
  };

  const runOnCurrent = async (action: () => Promise<ProductDetailResponse>) => {
    setBusy(true);
    setError(null);
    try {
      applyDetail(await action());
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const buildBody = (): ProductWriteBody | null => {
    const price = Number(form.price.replace(/[,\s]/g, ""));
    if (!form.name.trim() || !form.sku.trim() || !Number.isFinite(price) || price <= 0) {
      setError("Nhập tên, SKU và giá bán lớn hơn 0.");
      return null;
    }
    if (!form.categoryId) {
      setError("Phải chọn danh mục cho sản phẩm.");
      return null;
    }
    if (form.slug.trim() && !SLUG_PATTERN.test(form.slug.trim())) {
      setError("Slug chỉ gồm chữ thường, số và dấu gạch ngang.");
      return null;
    }

    const originalPrice = form.originalPrice.trim()
      ? Number(form.originalPrice.replace(/[,\s]/g, ""))
      : undefined;
    if (originalPrice !== undefined && (!Number.isFinite(originalPrice) || originalPrice <= 0)) {
      setError("Giá gốc phải là số lớn hơn 0, hoặc để trống.");
      return null;
    }

    return {
      name: form.name.trim(),
      slug: form.slug.trim() || undefined,
      sku: form.sku.trim(),
      price,
      originalPrice,
      description: form.description.trim() || undefined,
      material: form.material.trim() || undefined,
      careInstructions: form.careInstructions.trim() || undefined,
      tag: form.tag.trim() || undefined,
      categoryId: form.categoryId,
      status: form.status,
      isSummer: form.isSummer,
      isFeatured: form.isFeatured,
    };
  };

  const save = async () => {
    const body = buildBody();
    if (!body) return;

    setBusy(true);
    setError(null);
    try {
      if (current) {
        applyDetail(await adminProducts.update(current.id, body));
      } else {
        const created = await adminProducts.create(body);
        applyDetail(created);
      }
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const pickFile = (handler: (file: File) => Promise<ProductDetailResponse>) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    input.onchange = () => {
      const file = input.files?.[0];
      if (file) void runOnCurrent(() => handler(file));
    };
    input.click();
  };

  const missingSizes = current
    ? ALL_SIZES.filter((size) => !current.variants.some((v) => v.size === size))
    : [];

  return (
    <>
      <div className="mb-4 flex items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-ink">Sản phẩm</h1>
        <PrimaryButton onClick={openCreate} disabled={busy || categories.length === 0}>
          Thêm sản phẩm
        </PrimaryButton>
      </div>

      <AdminErrorBar message={error} onDismiss={() => setError(null)} />

      <AdminNotice>
        Máy chủ chưa hỗ trợ tìm kiếm ở danh sách quản trị, nên ô dưới đây chỉ lọc trong trang đang
        xem. Sản phẩm "Đang bán" buộc phải có ảnh bìa; chưa có ảnh thì máy chủ giữ sản phẩm ở
        trạng thái ẩn.
      </AdminNotice>

      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Lọc theo tên hoặc SKU (trong trang này)"
        className="mb-4 w-full max-w-sm rounded-xl border border-sand-200 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-clay-400"
      />

      <TableShell>
        <thead>
          <tr>
            <Th>Sản phẩm</Th>
            <Th>Giá</Th>
            <Th>Danh mục</Th>
            <Th>Trạng thái</Th>
            <Th>Thao tác</Th>
          </tr>
        </thead>
        <tbody>
          {visible.length === 0 ? (
            <tr>
              <Td className="text-xs text-mute">
                {busy ? "Đang tải..." : "Không có sản phẩm nào khớp."}
              </Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
            </tr>
          ) : (
            visible.map((product) => (
              <tr key={product.id}>
                <Td>
                  <div className="flex items-start gap-3">
                    {product.thumbnail ? (
                      <img
                        src={product.thumbnail}
                        alt=""
                        className="h-14 w-11 shrink-0 rounded-md object-cover"
                      />
                    ) : (
                      <div className="h-14 w-11 shrink-0 rounded-md bg-sand-100" />
                    )}
                    <span>
                      <span className="block font-medium text-ink">{product.name}</span>
                      <span className="block text-[11px] text-mute">SKU {product.sku || "—"}</span>
                    </span>
                  </div>
                </Td>
                <Td className="whitespace-nowrap text-xs font-bold text-clay-600">
                  {formatMoney(product.price)}
                </Td>
                <Td className="text-xs text-mute">{product.categoryName ?? "—"}</Td>
                <Td>
                  <StatusBadge
                    label={STATUS_LABEL[product.status]}
                    tone={product.status === "ACTIVE" ? "good" : "warn"}
                  />
                  {!product.thumbnail && (
                    <span className="mt-1 block">
                      <StatusBadge label="chưa có ảnh bìa" tone="bad" />
                    </span>
                  )}
                </Td>
                <Td>
                  <div className="flex flex-wrap gap-2">
                    <GhostButton onClick={() => void openEdit(product)} disabled={busy}>
                      Sửa
                    </GhostButton>
                    <ConfirmButton
                      label="Xoá"
                      disabled={busy}
                      onConfirm={() => {
                        void (async () => {
                          setBusy(true);
                          try {
                            await adminProducts.remove(product.id);
                            await load(page);
                          } catch (err) {
                            setError(errorMessage(err));
                          } finally {
                            setBusy(false);
                          }
                        })();
                      }}
                    />
                  </div>
                </Td>
              </tr>
            ))
          )}
        </tbody>
      </TableShell>

      <Pager
        page={page}
        totalPages={totalPages}
        totalElements={totalElements}
        busy={busy}
        onGoToPage={(target) => void load(target)}
      />

      {formOpen && (
        <AdminModal
          title={current ? `Sửa ${current.name}` : "Thêm sản phẩm"}
          onClose={closeForm}
          wide
          footer={
            <>
              <GhostButton onClick={closeForm}>Đóng</GhostButton>
              <PrimaryButton onClick={() => void save()} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu thông tin"}
              </PrimaryButton>
            </>
          }
        >
          <div className="grid gap-5 sm:grid-cols-2">
            <section>
              <Field
                label="Tên sản phẩm"
                value={form.name}
                onChange={(v) => setForm({ ...form, name: v })}
                required
              />
              <Field
                label="Slug"
                value={form.slug}
                onChange={(v) => setForm({ ...form, slug: v })}
                hint="Để trống thì máy chủ tự sinh từ tên."
              />
              <Field
                label="SKU"
                value={form.sku}
                onChange={(v) => setForm({ ...form, sku: v })}
                required
                hint="Mã nội bộ, phải khác mọi sản phẩm hiện có."
              />
              <Field
                label="Giá bán (đ)"
                value={form.price}
                onChange={(v) => setForm({ ...form, price: v })}
                required
              />
              <Field
                label="Giá gốc (đ)"
                value={form.originalPrice}
                onChange={(v) => setForm({ ...form, originalPrice: v })}
                hint="Để trống nếu không giảm giá."
              />
              <SelectField
                label="Danh mục"
                value={form.categoryId}
                options={categoryOptions}
                onChange={(v) => setForm({ ...form, categoryId: v })}
                required
              />
              <SelectField<RecordStatus>
                label="Trạng thái"
                value={form.status === "DELETED" ? "ACTIVE" : form.status}
                options={[
                  { value: "ACTIVE", label: STATUS_LABEL.ACTIVE },
                  { value: "HIDDEN", label: STATUS_LABEL.HIDDEN },
                ]}
                onChange={(v) => setForm({ ...form, status: v })}
              />
              <CheckboxField
                label="Hàng hè"
                checked={form.isSummer}
                onChange={(v) => setForm({ ...form, isSummer: v })}
              />
              <CheckboxField
                label="Nổi bật trên trang chủ"
                checked={form.isFeatured}
                onChange={(v) => setForm({ ...form, isFeatured: v })}
              />
            </section>

            <section>
              <Field
                label="Nhãn"
                value={form.tag}
                onChange={(v) => setForm({ ...form, tag: v })}
                placeholder="Signature"
              />
              <Field
                label="Mô tả"
                value={form.description}
                onChange={(v) => setForm({ ...form, description: v })}
                textarea
              />
              <Field
                label="Chất liệu"
                value={form.material}
                onChange={(v) => setForm({ ...form, material: v })}
                textarea
              />
              <Field
                label="Hướng dẫn bảo quản"
                value={form.careInstructions}
                onChange={(v) => setForm({ ...form, careInstructions: v })}
                textarea
              />
              <p className="text-[11px] leading-relaxed text-mute">
                Ô để trống nghĩa là GIỮ NGUYÊN giá trị cũ, không phải xoá — đây là quy ước cập
                nhật một phần của máy chủ.
              </p>
            </section>
          </div>

          {!current ? (
            <p className="mt-5 rounded-xl border border-sand-200 bg-sand-50 px-4 py-3 text-[11.5px] leading-relaxed text-mute">
              Lưu thông tin trước, sau đó mới thêm được ảnh và tồn kho (cần mã sản phẩm do máy chủ
              sinh).
            </p>
          ) : (
            <>
              <section className="mt-6 border-t border-sand-200 pt-5">
                <h4 className="mb-3 text-[10.5px] font-bold uppercase tracking-wider text-mute">
                  Ảnh
                </h4>

                {current.gallery.length === 0 ? (
                  <p className="text-[11.5px] leading-relaxed text-mute">
                    Chưa có ảnh nào. Thêm ít nhất một ảnh rồi đặt làm ảnh bìa để sản phẩm được bán.
                  </p>
                ) : (
                  <div className="grid grid-cols-3 gap-3 sm:grid-cols-5">
                    {current.gallery.map((image) => {
                      const isThumb = current.thumbnail === image.imageUrl;
                      return (
                        <div key={image.id} className="space-y-1.5">
                          <div className="relative">
                            <img
                              src={image.imageUrl}
                              alt=""
                              className="aspect-[3/4] w-full rounded-lg object-cover"
                            />
                            {isThumb && (
                              <span className="absolute left-1 top-1 rounded-full bg-ink px-1.5 py-0.5 text-[8.5px] font-bold uppercase text-white">
                                bìa
                              </span>
                            )}
                          </div>
                          <div className="flex flex-wrap gap-1">
                            {!isThumb && (
                              <button
                                type="button"
                                disabled={busy}
                                onClick={() =>
                                  void runOnCurrent(() =>
                                    adminProducts.selectThumbnail(current.id, image.id)
                                  )
                                }
                                className="text-[10px] font-semibold text-clay-600 hover:underline"
                              >
                                Đặt bìa
                              </button>
                            )}
                            <button
                              type="button"
                              disabled={busy}
                              onClick={() =>
                                pickFile((file) =>
                                  adminProducts.replaceImage(current.id, image.id, file)
                                )
                              }
                              className="text-[10px] font-semibold text-mute hover:underline"
                            >
                              Thay
                            </button>
                            <button
                              type="button"
                              disabled={busy}
                              onClick={() =>
                                void runOnCurrent(() =>
                                  adminProducts.removeImage(current.id, image.id)
                                )
                              }
                              className="text-[10px] font-semibold text-rose-600 hover:underline"
                            >
                              Xoá
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                <div className="mt-3 flex flex-wrap gap-2">
                  <GhostButton
                    disabled={busy}
                    onClick={() => pickFile((file) => adminProducts.addImage(current.id, file))}
                  >
                    Thêm ảnh
                  </GhostButton>
                  <GhostButton
                    disabled={busy}
                    onClick={() =>
                      pickFile((file) => adminProducts.uploadThumbnail(current.id, file))
                    }
                  >
                    Tải ảnh bìa
                  </GhostButton>
                </div>
                <p className="mt-2 text-[11px] leading-relaxed text-mute">
                  Không xoá được ảnh cuối cùng của một sản phẩm đang bán — hãy chuyển sản phẩm sang
                  trạng thái ẩn trước.
                </p>
              </section>

              <section className="mt-6 border-t border-sand-200 pt-5">
                <h4 className="mb-3 text-[10.5px] font-bold uppercase tracking-wider text-mute">
                  Tồn kho theo size
                </h4>

                {current.variants.length === 0 ? (
                  <p className="text-[11.5px] leading-relaxed text-mute">
                    Chưa khai size nào. Khách không đặt được hàng khi sản phẩm chưa có size với số
                    lượng tồn.
                  </p>
                ) : (
                  <ul className="space-y-2">
                    {current.variants.map((variant) => (
                      <VariantRow
                        key={variant.id}
                        size={variant.size}
                        stock={variant.stockQuantity}
                        busy={busy}
                        onSave={(stock) =>
                          void runOnCurrent(() =>
                            adminProducts.updateVariant(current.id, variant.id, {
                              stockQuantity: stock,
                              expectedVersion: variant.version,
                            })
                          )
                        }
                        onRemove={() =>
                          void runOnCurrent(() =>
                            adminProducts.removeVariant(current.id, variant.id)
                          )
                        }
                      />
                    ))}
                  </ul>
                )}

                {missingSizes.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {missingSizes.map((size) => (
                      <GhostButton
                        key={size}
                        disabled={busy}
                        onClick={() =>
                          void runOnCurrent(() =>
                            adminProducts.addVariant(current.id, { size, stockQuantity: 0 })
                          )
                        }
                      >
                        + Size {size}
                      </GhostButton>
                    ))}
                  </div>
                )}

                <p className="mt-2 text-[11px] leading-relaxed text-mute">
                  Nếu có người khác vừa sửa cùng một size, máy chủ sẽ từ chối để tránh ghi đè số
                  liệu kho. Lúc đó chỉ cần đóng và mở lại sản phẩm rồi sửa tiếp.
                </p>
              </section>
            </>
          )}
        </AdminModal>
      )}
    </>
  );
}

function VariantRow({
  size,
  stock,
  busy,
  onSave,
  onRemove,
}: {
  size: ProductSize;
  stock: number;
  busy?: boolean;
  onSave: (stock: number) => void;
  onRemove: () => void;
}) {
  const [value, setValue] = useState(String(stock));

  useEffect(() => {
    setValue(String(stock));
  }, [stock]);

  const parsed = Number(value);
  const dirty = Number.isFinite(parsed) && parsed >= 0 && parsed !== stock;

  return (
    <li className="flex items-center gap-3">
      <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-sand-100 text-sm font-bold text-ink">
        {size}
      </span>
      <input
        value={value}
        onChange={(e) => setValue(e.target.value)}
        className="w-24 rounded-xl border border-sand-200 bg-sand-50 px-3 py-2 text-sm outline-none focus:border-clay-400"
      />
      <GhostButton disabled={busy || !dirty} onClick={() => onSave(parsed)}>
        Lưu
      </GhostButton>
      <ConfirmButton label="Xoá size" onConfirm={onRemove} disabled={busy} />
    </li>
  );
}
