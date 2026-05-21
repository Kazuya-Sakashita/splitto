import { toApiError } from "@/lib/api/problemDetailsError"
import type { GroupListResponse } from "@/types/groups"

export type Group = {
  public_id: string
  name: string
  currency: string
  created_at?: string
  updated_at?: string
}

export type CreateGroupResponse = {
  group: Group
}

const DEFAULT_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3000"

function normalizeBaseUrl(baseUrl: string) {
  return baseUrl.replace(/\/+$/, "")
}

function buildUrl(path: string, baseUrl = DEFAULT_BASE_URL) {
  const base = normalizeBaseUrl(baseUrl)
  const p = path.startsWith("/") ? path : `/${path}`
  return `${base}${p}`
}

type RequestOptions = RequestInit & {
  token?: string
  baseUrl?: string
}

async function requestJson<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { token, baseUrl, ...init } = options

  const headers = new Headers(options.headers)
  headers.set("Accept", "application/json")

  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json")
  }

  if (token) {
    headers.set("Authorization", `Bearer ${token}`)
  }

  const res = await fetch(buildUrl(path, baseUrl), {
    ...init,
    headers,
    cache: init.cache ?? "no-store",
  })

  if (!res.ok) {
    throw await toApiError(res)
  }

  return (await res.json()) as T
}

/**
 * POST /api/v1/groups
 */
export type CreateGroupPayload = {
  group: {
    name: string
    currency: string
  }
}

export async function createGroup(
  payload: CreateGroupPayload,
  opts: { token?: string; baseUrl?: string } = {},
) {
  return requestJson<CreateGroupResponse>("/api/v1/groups", {
    method: "POST",
    body: JSON.stringify(payload),
    token: opts.token,
    baseUrl: opts.baseUrl,
  })
}

/**
 * GET /api/v1/groups?page=1
 */
export async function fetchGroups(
  params: { page?: number } = {},
  opts: { token?: string; baseUrl?: string } = {},
): Promise<GroupListResponse> {
  const search = new URLSearchParams()
  if (params.page) search.set("page", String(params.page))
  const path = search.toString() ? `/api/v1/groups?${search.toString()}` : "/api/v1/groups"

  return requestJson<GroupListResponse>(path, {
    method: "GET",
    token: opts.token,
    baseUrl: opts.baseUrl,
  })
}

/**
 * POST /api/v1/groups/:groupId/members
 */
export type AddMemberPayload = {
  user_id: string
}

export async function addMember(
  groupId: string,
  payload: AddMemberPayload,
  opts: { token?: string; baseUrl?: string } = {},
): Promise<void> {
  await requestJson<unknown>(`/api/v1/groups/${encodeURIComponent(groupId)}/members`, {
    method: "POST",
    body: JSON.stringify(payload),
    token: opts.token,
    baseUrl: opts.baseUrl,
  })
}

/**
 * DELETE /api/v1/groups/:groupId/members/:memberId
 *
 * - 204 No Content を期待。レスポンスボディは無し
 * - 失敗時は ApiError を throw（401/403/404/422）
 */
export async function removeMember(
  groupId: string,
  memberId: string,
  opts: { token?: string; baseUrl?: string } = {},
): Promise<void> {
  const path = `/api/v1/groups/${encodeURIComponent(groupId)}/members/${encodeURIComponent(memberId)}`
  const headers = new Headers()
  headers.set("Accept", "application/json")
  if (opts.token) {
    headers.set("Authorization", `Bearer ${opts.token}`)
  }

  const res = await fetch(buildUrl(path, opts.baseUrl), {
    method: "DELETE",
    headers,
    cache: "no-store",
  })

  if (res.status === 204) return
  if (!res.ok) {
    throw await toApiError(res)
  }
  throw new Error(`Unexpected status: ${res.status}`)
}
