import { useCallback, useEffect, useState } from "react";
import { adminCollections, adminProducts } from "@/api/admin";
import type {
  CollectionDetailResponse,
  CollectionSummaryResponse,
  ProductResponse,
} from "@/api/types";
import {
  AdminErrorBar,
  AdminModal,
  AdminNotice,
  ConfirmButton,
  Field,
  GhostButton,
  Pager,
  PrimaryButton,
  StatusBadge,
  TableShell,
  Td,
  Th,
  errorMessage,
} from "@/components/admin/ui";

const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export function AdminCollectionsPage() {
  const [collections, setCollections] = useState<CollectionSummaryResponse[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [allProducts, setAllProducts] = useState<ProductResponse[]>([]);
  const [formOpen, setFormOpen] = useState(false);
  const [current, setCurrent] = useState<CollectionDetailResponse | null>(null);
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [picked, setPicked] = useState<string[]>([]);

  const load = useCallback(async (target = 0) => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminCollections.list({ page: target, size: 20 });
      setCollections(result.content);
      setPage(result.page);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch (err) {
      setError(errorMessage(err, "Không tải được danh sách bộ sưu tập."));
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    void load(0);
    adminProducts
      .list({ size: 100 })
      .then((result) => setAllProducts(result.content))
      .catch(() => setAllProducts([]));
  }, [load]);

  const openCreate = () => {
    setCurrent(null);
    setName("");
    setSlug("");
    setPicked([]);
    setFormOpen(true);
  };

  const openEdit = async (collection: CollectionSummaryResponse) => {
    setBusy(true);
    setError(null);
    try {
      const detail = await adminCollections.get(collection.id);
      setCurrent(detail);
      setName(detail.collectionName);
      setSlug(detail.slug);
      setPicked(detail.products.map((p) => p.productId));
      setFormOpen(true);
    } catch (err) {
      setError(errorMessage(err, "Không tải được bộ sưu tập."));
    } finally {
      setBusy(false);
    }
  };

  const closeForm = () => {
    setFormOpen(false);
    setCurrent(null);
  };

  const runOnCurrent = async (action: () => Promise<CollectionDetailResponse>) => {
    setBusy(true);
    setError(null);
    try {
      const detail = await action();
      setCurrent(detail);
      setPicked(detail.products.map((p) => p.productId));
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const save = async () => {
    if (!name.trim()) {
      setError("Tên bộ sưu tập không được để trống.");
      return;
    }
    if (slug.trim() && !SLUG_PATTERN.test(slug.trim())) {
      setError("Slug chỉ gồm chữ thường, số và dấu gạch ngang.");
      return;
    }
    if (picked.length === 0) {
      setError("Bộ sưu tập phải có ít nhất một sản phẩm.");
      return;
    }

    if (!current) {
      setBusy(true);
      setError(null);
      try {
        const created = await adminCollections.create({
          collectionName: name.trim(),
          slug: slug.trim() || undefined,
          productIds: picked,
        });
        setCurrent(created);
        setPicked(created.products.map((p) => p.productId));
        await load(page);
      } catch (err) {
        setError(errorMessage(err));
      } finally {
        setBusy(false);
      }
      return;
    }

    setBusy(true);
    setError(null);
    try {
      const afterInfo = await adminCollections.update(current.id, {
        expectedVersion: current.version,
        collectionName: name.trim(),
        slug: slug.trim() || undefined,
      });

      const afterProducts = await adminCollections.replaceProducts(current.id, {
        expectedVersion: afterInfo.version,
        productIds: picked,
      });

      setCurrent(afterProducts);
      setPicked(afterProducts.products.map((p) => p.productId));
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const uploadCover = () => {
    if (!current) return;
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    input.onchange = () => {
      const file = input.files?.[0];
      if (file) void runOnCurrent(() => adminCollections.uploadCover(current.id, file, current.version));
    };
    input.click();
  };

  const togglePublish = (collection: CollectionSummaryResponse | CollectionDetailResponse) => {
    if (collection.status === "ACTIVE") {
      void runOnCurrent(() => adminCollections.hide(collection.id, collection.version));
      return;
    }
    if (!collection.coverImageUrl) {
      setError("Phải có ảnh bìa trước khi cho bộ sưu tập hiện ở shop.");
      return;
    }
    void runOnCurrent(() => adminCollections.publish(collection.id, collection.version));
  };

  const removeCollection = async (collection: CollectionSummaryResponse) => {
    setBusy(true);
    setError(null);
    try {
      await adminCollections.remove(collection.id, collection.version);
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <div className="mb-4 flex items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-ink">Bộ sưu tập</h1>
        <PrimaryButton onClick={openCreate} disabled={busy || allProducts.length === 0}>
          Thêm bộ sưu tập
        </PrimaryButton>
      </div>

      <AdminErrorBar message={error} onDismiss={() => setError(null)} />

      <AdminNotice>
        Mỗi bộ phải có ít nhất một sản phẩm, và phải có ảnh bìa mới cho hiện ở shop. Bộ đang hiện
        thì phải ẩn trước khi sửa nội dung. Nếu máy chủ báo "có người vừa sửa", hãy đóng rồi mở
        lại bộ đó và làm lại.
      </AdminNotice>

      <TableShell>
        <thead>
          <tr>
            <Th>Bộ sưu tập</Th>
            <Th>Slug</Th>
            <Th>Trạng thái</Th>
            <Th>Thao tác</Th>
          </tr>
        </thead>
        <tbody>
          {collections.length === 0 ? (
            <tr>
              <Td className="text-xs text-mute">
                {busy ? "Đang tải..." : "Chưa có bộ sưu tập nào."}
              </Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
            </tr>
          ) : (
            collections.map((collection) => (
              <tr key={collection.id}>
                <Td>
                  <div className="flex items-start gap-3">
                    {collection.coverImageUrl ? (
                      <img
                        src={collection.coverImageUrl}
                        alt=""
                        className="h-12 w-16 shrink-0 rounded-md object-cover"
                      />
                    ) : (
                      <div className="h-12 w-16 shrink-0 rounded-md bg-sand-100" />
                    )}
                    <span className="font-medium text-ink">{collection.collectionName}</span>
                  </div>
                </Td>
                <Td className="text-xs text-mute">/{collection.slug}</Td>
                <Td>
                  <StatusBadge
                    label={collection.status === "ACTIVE" ? "Đang hiện" : "Đang ẩn"}
                    tone={collection.status === "ACTIVE" ? "good" : "warn"}
                  />
                  {!collection.coverImageUrl && (
                    <span className="mt-1 block">
                      <StatusBadge label="chưa có ảnh bìa" tone="bad" />
                    </span>
                  )}
                </Td>
                <Td>
                  <div className="flex flex-wrap gap-2">
                    <GhostButton onClick={() => void openEdit(collection)} disabled={busy}>
                      Sửa
                    </GhostButton>
                    <GhostButton onClick={() => togglePublish(collection)} disabled={busy}>
                      {collection.status === "ACTIVE" ? "Ẩn" : "Cho hiện"}
                    </GhostButton>
                    <ConfirmButton
                      label="Xoá"
                      disabled={busy}
                      onConfirm={() => void removeCollection(collection)}
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
          title={current ? `Sửa ${current.collectionName}` : "Thêm bộ sưu tập"}
          onClose={closeForm}
          wide
          footer={
            <>
              <GhostButton onClick={closeForm}>Đóng</GhostButton>
              <PrimaryButton onClick={() => void save()} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu"}
              </PrimaryButton>
            </>
          }
        >
          {current?.status === "ACTIVE" && (
            <div className="mb-4 flex items-center gap-3 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3">
              <p className="flex-1 text-[11.5px] leading-relaxed text-amber-800">
                Bộ đang hiện ở shop. Máy chủ yêu cầu ẩn bộ trước khi sửa nội dung.
              </p>
              <GhostButton onClick={() => togglePublish(current)} disabled={busy}>
                Ẩn bộ
              </GhostButton>
            </div>
          )}

          <div className="grid gap-5 sm:grid-cols-2">
            <section>
              <Field label="Tên bộ sưu tập" value={name} onChange={setName} required />
              <Field
                label="Slug"
                value={slug}
                onChange={setSlug}
                hint="Để trống thì máy chủ tự sinh từ tên."
              />

              {current && (
                <>
                  <p className="mb-3 text-[11px] text-mute">
                    Phiên bản dữ liệu: {current.version}
                  </p>

                  <h4 className="mb-2 text-[10.5px] font-bold uppercase tracking-wider text-mute">
                    Ảnh bìa
                  </h4>
                  {current.coverImageUrl ? (
                    <img
                      src={current.coverImageUrl}
                      alt=""
                      className="mb-2 h-32 w-full rounded-xl object-cover"
                    />
                  ) : (
                    <p className="mb-2 text-[11.5px] leading-relaxed text-mute">
                      Chưa có ảnh bìa. Bắt buộc phải có mới cho bộ hiện ra shop.
                    </p>
                  )}
                  <GhostButton onClick={uploadCover} disabled={busy}>
                    {current.coverImageUrl ? "Thay ảnh bìa" : "Tải ảnh bìa"}
                  </GhostButton>

                  <div className="mt-4">
                    <PrimaryButton onClick={() => togglePublish(current)} disabled={busy}>
                      {current.status === "ACTIVE" ? "Ẩn khỏi shop" : "Cho hiện ở shop"}
                    </PrimaryButton>
                  </div>
                </>
              )}
            </section>

            <section>
              <h4 className="mb-2 text-[10.5px] font-bold uppercase tracking-wider text-mute">
                Sản phẩm trong bộ ({picked.length})
              </h4>
              <p className="mb-2 text-[11px] leading-relaxed text-mute">
                Lưu sẽ THAY toàn bộ danh sách của bộ bằng những gì đang chọn ở đây.
              </p>

              <div className="max-h-72 space-y-1 overflow-y-auto rounded-xl border border-sand-200 p-2">
                {allProducts.length === 0 ? (
                  <p className="p-2 text-[11.5px] text-mute">Chưa tải được danh sách sản phẩm.</p>
                ) : (
                  allProducts.map((product) => (
                    <label
                      key={product.id}
                      className="flex cursor-pointer items-start gap-2 rounded-lg px-2 py-1.5 hover:bg-sand-50"
                    >
                      <input
                        type="checkbox"
                        checked={picked.includes(product.id)}
                        onChange={(e) =>
                          setPicked((prev) =>
                            e.target.checked
                              ? [...prev, product.id]
                              : prev.filter((id) => id !== product.id)
                          )
                        }
                        className="mt-0.5 h-3.5 w-3.5"
                      />
                      <span className="text-xs text-ink">
                        {product.name}
                        <span className="block text-[10.5px] text-mute">
                          {product.status === "ACTIVE" ? "Đang bán" : "Đang ẩn"} · SKU{" "}
                          {product.sku || "—"}
                        </span>
                      </span>
                    </label>
                  ))
                )}
              </div>
            </section>
          </div>

          {!current && (
            <p className="mt-5 rounded-xl border border-sand-200 bg-sand-50 px-4 py-3 text-[11.5px] leading-relaxed text-mute">
              Lưu bộ trước, sau đó mới tải được ảnh bìa và cho hiện ở shop.
            </p>
          )}
        </AdminModal>
      )}
    </>
  );
}
