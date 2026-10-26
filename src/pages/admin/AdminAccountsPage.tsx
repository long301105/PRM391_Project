import { useCallback, useEffect, useMemo, useState } from "react";
import { adminAccounts, adminRoles } from "@/api/admin";
import type { AccountResponse, AccountStatusApi, RoleResponse } from "@/api/types";
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

const STATUS_LABEL: Record<AccountStatusApi, string> = {
  ACTIVE: "Đang hoạt động",
  DISABLED: "Đã vô hiệu",
  LOCKED: "Đang bị khoá",
};

const STATUS_HINT: Record<AccountStatusApi, string> = {
  ACTIVE: "Đăng nhập bình thường",
  DISABLED: "Chặn hẳn, không hẹn mở lại",
  LOCKED: "Chặn tới một thời điểm đã định",
};

function statusTone(status: AccountStatusApi) {
  if (status === "ACTIVE") return "good" as const;
  if (status === "LOCKED") return "bad" as const;
  return "warn" as const;
}

export function AdminAccountsPage() {
  const [accounts, setAccounts] = useState<AccountResponse[]>([]);
  const [roles, setRoles] = useState<RoleResponse[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<AccountResponse | null>(null);
  const [statusTarget, setStatusTarget] = useState<AccountResponse | null>(null);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [roleId, setRoleId] = useState("");
  const [status, setStatus] = useState<AccountStatusApi>("ACTIVE");
  const [lockedUntil, setLockedUntil] = useState("");

  const load = useCallback(async (target = 0) => {
    setBusy(true);
    setError(null);
    try {
      const result = await adminAccounts.list({ page: target, size: 20 });
      setAccounts(result.content);
      setPage(result.page);
      setTotalPages(result.totalPages);
      setTotalElements(result.totalElements);
    } catch (err) {
      setError(errorMessage(err, "Không tải được danh sách tài khoản."));
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    void load(0);
    adminRoles
      .list({ size: 50 })
      .then((result) => setRoles(result.content))
      .catch(() => setRoles([]));
  }, [load]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return accounts;
    return accounts.filter(
      (account) =>
        account.email.toLowerCase().includes(q) ||
        (account.roleName ?? "").toLowerCase().includes(q)
    );
  }, [accounts, query]);

  const roleOptions = roles.map((role) => ({ value: role.id, label: role.roleName }));

  const openCreate = () => {
    setEmail("");
    setPassword("");
    setRoleId(roles[0]?.id ?? "");
    setCreating(true);
  };

  const openEdit = (account: AccountResponse) => {
    setEmail(account.email);
    setRoleId(account.roleId ?? "");
    setEditing(account);
  };

  const openStatus = (account: AccountResponse) => {
    setStatus(account.status);
    setLockedUntil(account.lockedUntil ? account.lockedUntil.slice(0, 10) : "");
    setStatusTarget(account);
  };

  const closeForms = () => {
    setCreating(false);
    setEditing(null);
    setStatusTarget(null);
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

  const saveCreate = () => {
    if (!email.trim() || !password || !roleId) {
      setError("Nhập email, mật khẩu và chọn role.");
      return;
    }
    if (password.length < 8 || !/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(password)) {
      setError("Mật khẩu cần tối thiểu 8 ký tự, có chữ hoa, chữ thường và số.");
      return;
    }
    void run(() => adminAccounts.create({ email: email.trim(), password, roleId }));
  };

  const saveEdit = () => {
    if (!editing) return;
    void run(() =>
      adminAccounts.update(editing.id, {
        email: email.trim() || undefined,
        roleId: roleId || undefined,
      })
    );
  };

  const saveStatus = () => {
    if (!statusTarget) return;
    const iso =
      status === "LOCKED" && lockedUntil
        ? new Date(`${lockedUntil}T23:59:00`).toISOString()
        : undefined;
    void run(() => adminAccounts.updateStatus(statusTarget.id, { status, lockedUntil: iso }));
  };

  return (
    <>
      <div className="mb-4 flex items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-bold text-ink">Tài khoản</h1>
        <PrimaryButton onClick={openCreate} disabled={busy || roles.length === 0}>
          Tạo tài khoản
        </PrimaryButton>
      </div>

      <AdminErrorBar message={error} onDismiss={() => setError(null)} />

      <AdminNotice>
        Máy chủ chưa hỗ trợ tìm kiếm tài khoản, nên ô dưới đây chỉ lọc trong trang đang xem. Ở
        đây chỉ đổi được email và role; tên, số điện thoại và địa chỉ thuộc hồ sơ cá nhân và chỉ
        chính chủ sửa được. Đổi role sẽ đá tài khoản đó ra khỏi mọi thiết bị đang đăng nhập.
      </AdminNotice>

      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Lọc theo email hoặc role (trong trang này)"
        className="mb-4 w-full max-w-sm rounded-xl border border-sand-200 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-clay-400"
      />

      <TableShell>
        <thead>
          <tr>
            <Th>Email</Th>
            <Th>Role</Th>
            <Th>Trạng thái</Th>
            <Th>Thao tác</Th>
          </tr>
        </thead>
        <tbody>
          {visible.length === 0 ? (
            <tr>
              <Td className="text-xs text-mute">
                {busy ? "Đang tải..." : "Không có tài khoản nào khớp."}
              </Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
              <Td>{null}</Td>
            </tr>
          ) : (
            visible.map((account) => (
              <tr key={account.id}>
                <Td>
                  <span className="font-medium text-ink">{account.email}</span>
                  <div className="mt-1 flex flex-wrap gap-1.5">
                    {account.provider === "GOOGLE" && <StatusBadge label="google" />}
                    {!account.hasPassword && <StatusBadge label="chưa có mật khẩu" tone="warn" />}
                  </div>
                </Td>
                <Td>
                  <StatusBadge
                    label={account.roleName ?? "không role"}
                    tone={(account.roleName ?? "").toUpperCase() === "ADMIN" ? "warn" : "neutral"}
                  />
                </Td>
                <Td>
                  <StatusBadge label={STATUS_LABEL[account.status]} tone={statusTone(account.status)} />
                  {account.status === "LOCKED" && account.lockedUntil && (
                    <p className="mt-1 text-[11px] text-mute">
                      Mở khoá {new Date(account.lockedUntil).toLocaleString("vi-VN")}
                    </p>
                  )}
                </Td>
                <Td>
                  <div className="flex flex-wrap gap-2">
                    <GhostButton onClick={() => openEdit(account)} disabled={busy}>
                      Sửa
                    </GhostButton>
                    <GhostButton onClick={() => openStatus(account)} disabled={busy}>
                      Trạng thái
                    </GhostButton>
                    <ConfirmButton
                      label="Xoá"
                      onConfirm={() => void run(() => adminAccounts.remove(account.id))}
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

      {creating && (
        <AdminModal
          title="Tạo tài khoản"
          onClose={closeForms}
          footer={
            <>
              <GhostButton onClick={closeForms}>Thôi</GhostButton>
              <PrimaryButton onClick={saveCreate} disabled={busy}>
                {busy ? "Đang tạo..." : "Tạo"}
              </PrimaryButton>
            </>
          }
        >
          <Field label="Email" value={email} onChange={setEmail} type="email" required />
          <Field
            label="Mật khẩu"
            value={password}
            onChange={setPassword}
            type="password"
            required
            hint="Tối thiểu 8 ký tự, phải có chữ hoa, chữ thường và số."
          />
          <SelectField
            label="Role"
            value={roleId}
            options={roleOptions}
            onChange={setRoleId}
            required
          />
          <p className="text-[11px] leading-relaxed text-mute">
            Tài khoản tạo ở đây dùng được ngay, không phải xác minh mã OTP qua email như luồng
            khách tự đăng ký.
          </p>
        </AdminModal>
      )}

      {editing && (
        <AdminModal
          title={`Sửa ${editing.email}`}
          onClose={closeForms}
          footer={
            <>
              <GhostButton onClick={closeForms}>Thôi</GhostButton>
              <PrimaryButton onClick={saveEdit} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu"}
              </PrimaryButton>
            </>
          }
        >
          <Field label="Email" value={email} onChange={setEmail} type="email" required />
          <SelectField label="Role" value={roleId} options={roleOptions} onChange={setRoleId} />
        </AdminModal>
      )}

      {statusTarget && (
        <AdminModal
          title="Đổi trạng thái"
          onClose={closeForms}
          footer={
            <>
              <GhostButton onClick={closeForms}>Thôi</GhostButton>
              <PrimaryButton onClick={saveStatus} disabled={busy}>
                {busy ? "Đang lưu..." : "Lưu"}
              </PrimaryButton>
            </>
          }
        >
          <p className="mb-3 text-xs text-mute">{statusTarget.email}</p>

          <div className="space-y-2">
            {(["ACTIVE", "DISABLED", "LOCKED"] as AccountStatusApi[]).map((value) => (
              <label
                key={value}
                className="flex cursor-pointer items-start gap-2.5 rounded-xl border border-sand-200 px-3.5 py-2.5"
              >
                <input
                  type="radio"
                  name="account-status"
                  checked={status === value}
                  onChange={() => setStatus(value)}
                  className="mt-0.5"
                />
                <span>
                  <span className="block text-sm text-ink">{STATUS_LABEL[value]}</span>
                  <span className="block text-[11px] text-mute">{STATUS_HINT[value]}</span>
                </span>
              </label>
            ))}
          </div>

          {status === "LOCKED" && (
            <div className="mt-3">
              <Field
                label="Khoá đến ngày"
                value={lockedUntil}
                onChange={setLockedUntil}
                type="date"
                hint="Phải là mốc trong tương lai. Để trống thì khoá tới khi admin mở lại."
              />
            </div>
          )}
        </AdminModal>
      )}
    </>
  );
}
