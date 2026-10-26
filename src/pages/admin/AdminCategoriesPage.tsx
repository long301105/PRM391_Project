import { useCallback, useEffect, useState } from "react";
import { adminCategories } from "@/api/admin";
import type { CategoryResponse, RecordStatus } from "@/api/types";
import {
  AdminErrorBar,
  AdminModal,
  AdminNotice,
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

const STATUS_LABEL: Record<RecordStatus, string> = {
  ACTIVE: "Đang bán",
  HIDDEN: "Đang ẩn",
  DELETED: "Đã xoá",
};

export function AdminCategoriesPage() {
  const [categories, setCategories] = useState<CategoryResponse[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<CategoryResponse | null>(null);
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [status, setStatus] = useState<RecordStatus>("ACTIVE");

  const load = useCallback(async (target = 0) => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminCategories.list({ page: target, size: 50 });
      setCategories(result.content);
      setPage(result.page);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch (err) {
      setError(errorMessage(err, "Không tải được danh sách danh mục."));
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    void load(0);
  }, [load]);

  const openCreate = () => {
    setName("");
    setSlug("");
    setStatus("ACTIVE");
    setCreating(true);
  };

  const openEdit = (category: CategoryResponse) => {
    setName(category.categoryName);
    setSlug(category.slug);
    setStatus(category.status);
    setEditing(category);
  };

  const closeForms = () => {
    setCreating(false);
    setEditing(null);
  };

  const run = async (action: () => Promise<unknown>) => {
    setBusy(true);
    setError(null);
    try {
      await action();
      closeForms();
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const save = () => {
    if (!name.trim()) {
      setError("Tên danh mục không được để trống.");
      return;
    }
    if (slug.trim() && !SLUG_PATTERN.test(slug.trim())) {
      setError("Slug chỉ gồm chữ thường, số và dấu gạch ngang.");
      return;
    }

    if (editing) {
      void run(() =>
        adminCategories.update(editing.id, {
          categoryName: name.trim(),
          slug: slug.trim(),
          status,
        })
      );
    } else {
      void run(() =>
        adminCategories.create({
          categoryName: name.trim(),
          slug: slug.trim() || undefined,
        })
      );
    }
  };

  return (
    <>
      <div className="mb-4 flex items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-ink">Danh mục</h1>
        <PrimaryButton onClick={openCreate} disabled={busy}>
          Thêm danh mục
        </PrimaryButton>
      </div>

      <AdminErrorBar message={error} onDismiss={() => setError(null)} />

      <AdminNotice>
        Để trống slug thì máy chủ tự sinh từ tên. Không xoá được danh mục còn sản phẩm bên trong —
        hãy chuyển những sản phẩm đó sang danh mục khác trước.
      </AdminNotice>

      <TableShell>
        <thead>
          <tr>
            <Th>Tên</Th>
            <Th>Slug</Th>
            <Th>Trạng thái</Th>
            <Th>Thao tác</Th>
          </tr>
        </thead>
        <tbody>
          {categories.length === 0 ? (
            <tr>
              <Td className="text-xs text-mute">
                {busy ? "Đang tải..." : "Chưa có danh mục nào. Sản phẩm bắt buộc thuộc một danh mục."}
              </Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
            </tr>
          ) : (
            categories.map((category) => (
              <tr key={category.id}>
                <Td>
                  <span className="font-medium text-ink">{category.categoryName}</span>
                </Td>
                <Td className="text-xs text-mute">/{category.slug}</Td>
                <Td>
                  <StatusBadge
                    label={STATUS_LABEL[category.status]}
                    tone={category.status === "ACTIVE" ? "good" : "warn"}
                  />
                </Td>
                <Td>
                  <div className="flex flex-wrap gap-2">
                    <GhostButton onClick={() => openEdit(category)} disabled={busy}>
                      Sửa
                    </GhostButton>
                    <ConfirmButton
                      label="Xoá"
                      onConfirm={() => void run(() => adminCategories.remove(category.id))}
                      disabled={busy}
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

      {(creating || editing) && (
        <AdminModal
          title={editing ? `Sửa ${editing.categoryName}` : "Thêm danh mục"}
          onClose={closeForms}
          footer={
            <>
              <GhostButton onClick={closeForms}>Thôi</GhostButton>
              <PrimaryButton onClick={save} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu"}
              </PrimaryButton>
            </>
          }
        >
          <Field label="Tên danh mục" value={name} onChange={setName} required placeholder="Áo" />
          <Field
            label="Slug"
            value={slug}
            onChange={setSlug}
            placeholder="ao"
            hint="Để trống thì máy chủ tự sinh từ tên."
          />
          {editing && (
            <SelectField<RecordStatus>
              label="Trạng thái"
              value={status === "DELETED" ? "ACTIVE" : status}
              options={[
                { value: "ACTIVE", label: STATUS_LABEL.ACTIVE },
                { value: "HIDDEN", label: STATUS_LABEL.HIDDEN },
              ]}
              onChange={setStatus}
            />
          )}
        </AdminModal>
      )}
    </>
  );
}
