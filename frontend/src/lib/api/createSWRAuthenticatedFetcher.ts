import type { ApiError } from "@/lib/api/problemDetailsError"
import { getApiBaseUrl } from "@/lib/api/getApiBaseUrl"
import { toApiError } from "@/lib/api/problemDetailsError"

type AuthenticatedFetch = (
  input: RequestInfo | URL,
  init?: RequestInit
) => Promise<Response>

export function createSWRAuthenticatedFetcher<T>(
  authenticatedFetch: AuthenticatedFetch,
  path: string
) {
  return async (params?: Record<string, string | number | boolean | undefined>) => {
    const base = getApiBaseUrl()
    const url = new URL(path, base)

    if (params) {
      for (const [k, v] of Object.entries(params)) {
        if (v == null) continue
        url.searchParams.set(k, String(v))
      }
    }

    const res = await authenticatedFetch(url.toString(), { method: "GET" })
    if (!res.ok) throw (await toApiError(res)) as ApiError

    return (await res.json()) as T
  }
}
