import { apiFetch } from "@/lib/api/http"
import type { GroupListResponse } from "@/types/groups"

export async function fetchGroups(params: { page?: number; token: string }) {
  const page = params.page ?? 1
  const url = new URL("/api/v1/groups", process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3000")
  url.searchParams.set("page", String(page))

  return apiFetch<GroupListResponse>(url.toString(), {
    method: "GET",
    token: params.token,
  })
}
