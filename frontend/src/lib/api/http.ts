import type { ProblemDetails } from "@/types/problemDetails"

export class ApiError extends Error {
  problem: ProblemDetails
  constructor(problem: ProblemDetails) {
    super(problem.title)
    this.problem = problem
  }
}

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

  // RFC9457
  const contentType = res.headers.get("content-type") ?? ""
  if (contentType.includes("application/problem+json")) {
    const problem = (await res.json()) as ProblemDetails
    throw new ApiError(problem)
  }

  // fallback
  throw new Error(`Request failed: ${res.status}`)
}
