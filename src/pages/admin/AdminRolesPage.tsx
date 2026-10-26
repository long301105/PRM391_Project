import { useCallback, useEffect, useState } from "react";
import { adminRoles } from "@/api/admin";
import type { RoleResponse } from "@/api/types";
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

export function AdminRolesPage() {
  const [roles, setRoles] = useState<RoleResponse[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [editing, setEditing] = useState<RoleResponse | null>(null);
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  const load = useCallback(async (target = 0) => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminRoles.list({ page: target, size: 50 });
      setRoles(result.content);
      setPage(result.page);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch (err) {
      setError(errorMessage(err, "Không tải được danh sách role."));
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    void load(0);
  }, [load]);

  const openCreate = () => {
    setName("");
    setDescription("");
    setCreating(true);
  };

  const openEdit = (role: RoleResponse) => {
    setName(role.roleName);
    setDescription(role.description ?? "");
    setEditing(role);
  };

  const closeForm = () => {
    setCreating(false);
    setEditing(null);
  };

  const save = async () => {
    if (!name.trim()) {
      setError("Tên role không được để trống.");
      return;
    }

    setBusy(true);
    setError(null);
    try {
      if (editing) {
        await adminRoles.update(editing.id, {
          roleName: name.trim(),
          description: description.trim(),
        });
      } else {
        await adminRoles.create({
          roleName: name.trim(),
          description: description.trim() || undefined,
        });
      }
      closeForm();
      await load(page);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (role: RoleResponse) => {
    setBusy(true);
    setError(null);
    try {
      await adminRoles.remove(role.id);
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
        <h1 className="font-display text-2xl font-bold text-ink">Role</h1>
        <PrimaryButton onClick={openCreate} disabled={busy}>
          Thêm role
        </PrimaryButton>
      </div>

      <AdminErrorBar message={error} onDismiss={() => setError(null)} />

      <AdminNotice>
        Tên role được máy chủ tự viết HOA và phải duy nhất. Không xoá được role đang gán cho bất
        kỳ tài khoản nào — hãy đổi role của những tài khoản đó trước.
      </AdminNotice>

      <TableShell>
        <thead>
          <tr>
            <Th>Tên role</Th>
            <Th>Mô tả</Th>
            <Th>Thao tác</Th>
          </tr>
        </thead>
        <tbody>
          {roles.length === 0 ? (
            <tr>
              <Td className="text-xs text-mute">
                {busy ? "Đang tải..." : "Chưa có role nào."}
              </Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
            </tr>
          ) : (
            roles.map((role) => (
              <tr key={role.id}>
                <Td>
                  <span className="font-semibold text-ink">{role.roleName}</span>
                  {role.roleName.toUpperCase() === "ADMIN" && (
                    <span className="ml-2">
                      <StatusBadge label="hệ thống" tone="warn" />
                    </span>
                  )}
                </Td>
                <Td className="text-xs text-mute">{role.description || "—"}</Td>
                <Td>
                  <div className="flex flex-wrap gap-2">
                    <GhostButton onClick={() => openEdit(role)} disabled={busy}>
                      Sửa
                    </GhostButton>
                    <ConfirmButton label="Xoá" onConfirm={() => void remove(role)} disabled={busy} />
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
          title={editing ? `Sửa role ${editing.roleName}` : "Thêm role"}
          onClose={closeForm}
          footer={
            <>
              <GhostButton onClick={closeForm}>Thôi</GhostButton>
              <PrimaryButton onClick={() => void save()} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu"}
              </PrimaryButton>
            </>
          }
        >
          <Field label="Tên role" value={name} onChange={setName} required placeholder="STAFF" />
          <Field label="Mô tả" value={description} onChange={setDescription} textarea />
        </AdminModal>
      )}
    </>
  );
}
