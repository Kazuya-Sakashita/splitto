import { toApiError } from "@/lib/api/problemDetailsError"

export async function apiFetch<T>(
  input: RequestInfo | URL,
  init?: RequestInit & { token?: string }
): Promise<T> {
  const token = init?.token
  const headers = new Headers(init?.headers)

  headers.set("Accept", "application/json")
  if (token) headers.set("Authorization", `Bearer ${token}`)

  const res = await fetch(input, { ...init, headers })

  if (res.ok) {
    return (await res.json()) as T
  }

  throw await toApiError(res)
}
