import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { ArrowLeft, LogOut } from "lucide-react";
import { useAuth } from "@/context/AuthContext";
import { cn } from "@/utils/cn";

const NAV = [
  { to: "/admin/don-hang", label: "Đơn hàng" },
  { to: "/admin/san-pham", label: "Sản phẩm" },
  { to: "/admin/danh-muc", label: "Danh mục" },
  { to: "/admin/bo-suu-tap", label: "Bộ sưu tập" },
  { to: "/admin/tai-khoan", label: "Tài khoản" },
  { to: "/admin/role", label: "Role" },
];

export function AdminLayout() {
  const { isAdmin, isAuthenticated, checking, requireLogin, logout, account } = useAuth();
  const navigate = useNavigate();

  if (checking) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-sand-50">
        <p className="text-sm text-mute">Đang kiểm tra phiên đăng nhập...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <AdminGate
        title="Cần đăng nhập"
        message="Khu quản trị yêu cầu tài khoản có role ADMIN."
        actionLabel="Đăng nhập"
        onAction={requireLogin}
      />
    );
  }

  if (!isAdmin) {
    return (
      <AdminGate
        title="Không có quyền quản trị"
        message={`Tài khoản ${account?.email ?? ""} có role ${
          account?.roleName ?? "không xác định"
        }. Khu này chỉ dành cho role ADMIN.`}
        actionLabel="Về cửa hàng"
        onAction={() => navigate("/")}
      />
    );
  }

  return (
    <div className="min-h-screen bg-sand-50">
      <header className="border-b border-sand-200 bg-white">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-3 px-4 py-3.5">
          <button
            type="button"
            onClick={() => navigate("/")}
            className="flex items-center gap-1.5 text-xs font-semibold text-mute hover:text-ink"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            Cửa hàng
          </button>

          <span className="font-display text-lg font-bold text-ink">Quản trị</span>

          <div className="ml-auto flex items-center gap-3">
            <span className="hidden text-xs text-mute sm:inline">{account?.email}</span>
            <button
              type="button"
              onClick={async () => {
                await logout();
                navigate("/");
              }}
              className="flex items-center gap-1.5 rounded-full border border-sand-200 px-3 py-1.5 text-[11px] font-bold uppercase tracking-wider text-mute hover:bg-sand-100"
            >
              <LogOut className="h-3 w-3" />
              Đăng xuất
            </button>
          </div>
        </div>

        <nav className="mx-auto max-w-6xl overflow-x-auto px-4">
          <div className="flex gap-1 pb-2">
            {NAV.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  cn(
                    "whitespace-nowrap rounded-full px-4 py-2 text-xs font-bold transition",
                    isActive ? "bg-ink text-white" : "text-mute hover:bg-sand-100"
                  )
                }
              >
                {item.label}
              </NavLink>
            ))}
          </div>
        </nav>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-6">
        <Outlet />
      </main>
    </div>
  );
}

function AdminGate({
  title,
  message,
  actionLabel,
  onAction,
}: {
  title: string;
  message: string;
  actionLabel: string;
  onAction: () => void;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-sand-50 px-6">
      <div className="max-w-sm rounded-3xl border border-sand-200 bg-white p-8 text-center">
        <h1 className="font-display text-xl font-bold text-ink">{title}</h1>
        <p className="mt-2 text-xs leading-relaxed text-mute">{message}</p>
        <button
          type="button"
          onClick={onAction}
          className="mt-5 rounded-full bg-ink px-6 py-2.5 text-[11px] font-bold uppercase tracking-wider text-white"
        >
          {actionLabel}
        </button>
      </div>
    </div>
  );
}
