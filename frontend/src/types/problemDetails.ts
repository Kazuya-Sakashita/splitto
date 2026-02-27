export type ProblemDetails = {
  type: string
  title: string
  status: number
  detail: string
  reason: string
  instance?: string | null
  errors?: Record<string, string[]> | null
}
