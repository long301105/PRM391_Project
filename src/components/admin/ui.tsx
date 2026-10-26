"use client";

import { useEffect, useState } from "react";
import type { ReactNode } from "react";
import { X } from "lucide-react";
import { ApiError } from "@/lib/api";
import { cn } from "@/utils/cn";

export function errorMessage(error: unknown, fallback = "Thao tác không thành công."): string {
  if (error instanceof ApiError) return error.message;
  if (error instanceof Error && error.message) return error.message;
  return fallback;
}

export function AdminErrorBar({
  message,
  onDismiss,
}: {
  message: string | null;
  onDismiss?: () => void;
}) {
  if (!message) return null;
  return (
    <div className="mb-4 flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3">
      <p className="flex-1 text-xs leading-relaxed text-rose-800">{message}</p>
      {onDismiss && (
        <button type="button" onClick={onDismiss} className="text-rose-600" aria-label="Đóng">
          <X className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
  );
}

export function AdminNotice({ children }: { children: ReactNode }) {
  return (
    <p className="mb-4 rounded-xl border border-sand-200 bg-sand-50 px-4 py-3 text-[11.5px] leading-relaxed text-mute">
      {children}
    </p>
  );
}

type Tone = "neutral" | "good" | "warn" | "bad";

export function StatusBadge({ label, tone = "neutral" }: { label: string; tone?: Tone }) {
  const styles: Record<Tone, string> = {
    neutral: "bg-sand-100 text-mute",
    good: "bg-emerald-50 text-emerald-700",
    warn: "bg-amber-50 text-amber-800",
    bad: "bg-rose-50 text-rose-700",
  };
  return (
    <span
      className={cn(
        "inline-block rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide",
        styles[tone]
      )}
    >
      {label}
    </span>
  );
}

export function Pager({
  page,
  totalPages,
  totalElements,
  onGoToPage,
  busy,
}: {
  page: number;
  totalPages: number;
  totalElements: number;
  onGoToPage: (page: number) => void;
  busy?: boolean;
}) {
  return (
    <div className="mt-4 flex items-center justify-between text-xs text-mute">
      <span>{totalElements} bản ghi</span>
      {totalPages > 1 && (
        <div className="flex items-center gap-2">
          <button
            type="button"
            disabled={page <= 0 || busy}
            onClick={() => onGoToPage(page - 1)}
            className="rounded-full border border-sand-200 px-3 py-1.5 disabled:opacity-40"
          >
            Trước
          </button>
          <span>
            Trang {page + 1}/{totalPages}
          </span>
          <button
            type="button"
            disabled={page >= totalPages - 1 || busy}
            onClick={() => onGoToPage(page + 1)}
            className="rounded-full border border-sand-200 px-3 py-1.5 disabled:opacity-40"
          >
            Sau
          </button>
        </div>
      )}
    </div>
  );
}

export function AdminModal({
  title,
  children,
  onClose,
  footer,
  wide,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
  footer?: ReactNode;
  wide?: boolean;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-[4100] flex items-start justify-center overflow-y-auto bg-ink/60 p-4 backdrop-blur-sm sm:p-8"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className={cn(
          "relative w-full rounded-3xl bg-white p-6 shadow-2xl",
          wide ? "max-w-3xl" : "max-w-lg"
        )}
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Đóng"
          className="absolute right-4 top-4 rounded-full p-1.5 text-mute hover:bg-sand-100"
        >
          <X className="h-4 w-4" />
        </button>
        <h3 className="pr-8 font-display text-xl font-bold text-ink">{title}</h3>
        <div className="mt-4">{children}</div>
        {footer && <div className="mt-6 flex justify-end gap-2">{footer}</div>}
      </div>
    </div>
  );
}

export function Field({
  label,
  value,
  onChange,
  type = "text",
  hint,
  required,
  textarea,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  hint?: string;
  required?: boolean;
  textarea?: boolean;
  placeholder?: string;
}) {
  const className =
    "w-full rounded-xl border border-sand-200 bg-sand-50 px-3.5 py-2.5 text-sm text-ink outline-none transition focus:border-clay-400";

  return (
    <label className="mb-3 block">
      <span className="mb-1 block text-[11px] font-bold uppercase tracking-wider text-mute">
        {label}
        {required && <span className="text-rose-500"> *</span>}
      </span>
      {textarea ? (
        <textarea
          value={value}
          rows={3}
          placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          className={className}
        />
      ) : (
        <input
          type={type}
          value={value}
          placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          className={className}
        />
      )}
      {hint && <span className="mt-1 block text-[11px] leading-relaxed text-mute">{hint}</span>}
    </label>
  );
}

export function SelectField<T extends string>({
  label,
  value,
  options,
  onChange,
  hint,
  required,
}: {
  label: string;
  value: T | "";
  options: Array<{ value: T; label: string }>;
  onChange: (value: T) => void;
  hint?: string;
  required?: boolean;
}) {
  return (
    <label className="mb-3 block">
      <span className="mb-1 block text-[11px] font-bold uppercase tracking-wider text-mute">
        {label}
        {required && <span className="text-rose-500"> *</span>}
      </span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as T)}
        className="w-full rounded-xl border border-sand-200 bg-sand-50 px-3.5 py-2.5 text-sm text-ink outline-none focus:border-clay-400"
      >
        <option value="">— Chọn —</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {hint && <span className="mt-1 block text-[11px] leading-relaxed text-mute">{hint}</span>}
    </label>
  );
}

export function CheckboxField({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label className="mb-3 flex items-center gap-2.5 text-sm text-ink">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 rounded border-sand-300"
      />
      {label}
    </label>
  );
}

export function PrimaryButton({
  children,
  onClick,
  disabled,
  type = "button",
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  type?: "button" | "submit";
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className="rounded-full bg-ink px-5 py-2.5 text-[11px] font-bold uppercase tracking-wider text-white transition hover:bg-clay-600 disabled:opacity-50"
    >
      {children}
    </button>
  );
}

export function GhostButton({
  children,
  onClick,
  disabled,
  danger,
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  danger?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cn(
        "rounded-full border px-4 py-2 text-[11px] font-bold uppercase tracking-wider transition disabled:opacity-50",
        danger
          ? "border-rose-200 text-rose-700 hover:bg-rose-50"
          : "border-sand-200 text-mute hover:bg-sand-100"
      )}
    >
      {children}
    </button>
  );
}

export function ConfirmButton({
  label,
  confirmLabel = "Chắc chưa?",
  onConfirm,
  disabled,
}: {
  label: string;
  confirmLabel?: string;
  onConfirm: () => void;
  disabled?: boolean;
}) {
  const [armed, setArmed] = useState(false);

  useEffect(() => {
    if (!armed) return;
    const timer = window.setTimeout(() => setArmed(false), 4000);
    return () => window.clearTimeout(timer);
  }, [armed]);

  return (
    <GhostButton
      danger
      disabled={disabled}
      onClick={() => {
        if (armed) {
          setArmed(false);
          onConfirm();
        } else {
          setArmed(true);
        }
      }}
    >
      {armed ? confirmLabel : label}
    </GhostButton>
  );
}

export function TableShell({ children }: { children: ReactNode }) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-sand-200 bg-white">
      <table className="w-full min-w-[640px] text-left text-sm">{children}</table>
    </div>
  );
}

export function Th({ children }: { children: ReactNode }) {
  return (
    <th className="border-b border-sand-200 px-4 py-3 text-[10.5px] font-bold uppercase tracking-wider text-mute">
      {children}
    </th>
  );
}

export function Td({ children, className }: { children: ReactNode; className?: string }) {
  return <td className={cn("border-b border-sand-100 px-4 py-3 align-top", className)}>{children}</td>;
}
