
const BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/+$/, "") ??
  "http://localhost:8088/api/v1";

export class ApiError extends Error {
  readonly status: number;
  readonly fieldErrors?: Record<string, string>;

  constructor(status: number, message: string, fieldErrors?: Record<string, string>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.fieldErrors = fieldErrors;
  }

  get isUnauthorized() {
    return this.status === 401;
  }

  get isForbidden() {
    return this.status === 403;
  }

  get isConflict() {
    return this.status === 409;
  }

  get isNetwork() {
    return this.status === 0;
  }
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}

type Query = Record<string, string | number | boolean | undefined | null>;

function buildUrl(path: string, query?: Query): string {
  const url = new URL(BASE_URL + path);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null || value === "") continue;
      url.searchParams.set(key, String(value));
    }
  }
  return url.toString();
}

async function request<T>(
  method: "GET" | "POST" | "PATCH" | "PUT" | "DELETE",
  path: string,
  options: { body?: unknown; query?: Query; isFormData?: boolean } = {}
): Promise<T> {
  const { body, query, isFormData } = options;

  let response: Response;
  try {
    response = await fetch(buildUrl(path, query), {
      method,
      credentials: "include",
      headers: body !== undefined && !isFormData ? { "Content-Type": "application/json" } : undefined,
      body: body === undefined ? undefined : isFormData ? (body as FormData) : JSON.stringify(body),
    });
  } catch {
    throw new ApiError(0, "Không kết nối được tới máy chủ. Kiểm tra mạng hoặc khởi động backend.");
  }

  const text = await response.text();
  const payload = text ? safeParse(text) : null;

  if (!response.ok) {
    const message =
      pickString(payload, "message") ??
      pickString(payload, "error") ??
      `Yêu cầu không thành công (${response.status})`;
    throw new ApiError(response.status, message, pickFieldErrors(payload));
  }

  if (payload && typeof payload === "object" && "result" in payload) {
    return (payload as { result: T }).result;
  }
  return payload as T;
}

function safeParse(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function pickString(payload: unknown, key: string): string | undefined {
  if (payload && typeof payload === "object" && key in payload) {
    const value = (payload as Record<string, unknown>)[key];
    if (typeof value === "string" && value.trim()) return value;
  }
  return undefined;
}

function pickFieldErrors(payload: unknown): Record<string, string> | undefined {
  if (!payload || typeof payload !== "object" || !("errors" in payload)) return undefined;
  const errors = (payload as Record<string, unknown>).errors;
  if (!errors || typeof errors !== "object") return undefined;

  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(errors as Record<string, unknown>)) {
    result[key] = String(value);
  }
  return result;
}

export const api = {
  get: <T>(path: string, query?: Query) => request<T>("GET", path, { query }),
  post: <T>(path: string, body?: unknown) => request<T>("POST", path, { body }),
  patch: <T>(path: string, body?: unknown) => request<T>("PATCH", path, { body }),
  put: <T>(path: string, body?: unknown) => request<T>("PUT", path, { body }),
  del: <T>(path: string, query?: Query) => request<T>("DELETE", path, { query }),
  upload: <T>(method: "POST" | "PUT", path: string, file: File, field = "file", metadata?: unknown) => {
    const form = new FormData();
    form.append(field, file);
    if (metadata !== undefined) {
      form.append("metadata", new Blob([JSON.stringify(metadata)], { type: "application/json" }));
    }
    return request<T>(method, path, { body: form, isFormData: true });
  },
};
