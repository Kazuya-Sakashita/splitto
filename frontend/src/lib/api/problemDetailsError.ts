import type { ProblemDetails } from "@/types/problemDetails"

export type ApiErrorCode = "UNAUTHORIZED" | "FORBIDDEN" | "NOT_FOUND" | "API_ERROR"

export type ApiError = Error & {
  status?: number
  problem?: ProblemDetails
  code?: ApiErrorCode
}

export function statusToCode(status: number): ApiErrorCode {
  if (status === 401) return "UNAUTHORIZED"
  if (status === 403) return "FORBIDDEN"
  if (status === 404) return "NOT_FOUND"
  return "API_ERROR"
}

export async function toApiError(res: Response): Promise<ApiError> {
  const contentType = res.headers.get("content-type") ?? ""

  // RFC9457 (application/problem+json) を優先
  if (contentType.includes("application/problem+json")) {
    const problem = (await res.json()) as ProblemDetails

    const e = new Error(problem.title ?? "API_ERROR") as ApiError
    e.status = res.status
    e.code = statusToCode(res.status)
    e.problem = problem
    return e
  }

  // fallback：ProblemDetails 必須項目を埋める
  let detail = ""
  try {
    detail = await res.text()
  } catch {
    detail = ""
  }

  const problem: ProblemDetails = {
    type: "about:blank",
    title: `API_ERROR_${res.status}`,
    status: res.status,
    detail: detail || `Request failed with status ${res.status}`,
    reason: "unexpected_response",
    instance: null,
    errors: null,
  }

  const e = new Error(problem.title) as ApiError
  e.status = res.status
  e.code = statusToCode(res.status)
  e.problem = problem
  return e
}
