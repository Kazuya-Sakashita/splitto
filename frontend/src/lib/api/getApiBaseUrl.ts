export function getApiBaseUrl() {
  const base = process.env.NEXT_PUBLIC_API_BASE_URL
  if (base) return base

  // 本番/プレビューで localhost に飛ぶ事故を防ぐ
  if (process.env.NODE_ENV === "production") {
    throw new Error("NEXT_PUBLIC_API_BASE_URL is not set")
  }

  return "http://localhost:3000"
}
