"use client"

import { useState } from "react"
import { useAuthenticatedFetch } from "@/lib/api/authenticatedFetch"

export function MeDebugButton() {
  const authFetch = useAuthenticatedFetch()
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string>("")

  const onClick = async () => {
    setLoading(true)
    setResult("")

    try {
      const base = process.env.NEXT_PUBLIC_API_BASE_URL
      if (!base) throw new Error("NEXT_PUBLIC_API_BASE_URL is not set")

      const res = await authFetch(`${base}/api/v1/me`, { method: "GET" })
      const text = await res.text()

      setResult(`status: ${res.status}\n\n${text}`)
    } catch (e) {
      setResult(`error: ${String(e)}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="mt-6">
      <button
        type="button"
        onClick={onClick}
        disabled={loading}
        className="rounded-xl bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15 disabled:opacity-60"
      >
        {loading ? "calling /api/v1/me..." : "Rails /api/v1/me を叩く（JWT付き）"}
      </button>

      {result ? (
        <pre className="mt-3 whitespace-pre-wrap rounded-xl bg-black/30 p-4 text-xs text-white/80">
          {result}
        </pre>
      ) : null}
    </div>
  )
}
