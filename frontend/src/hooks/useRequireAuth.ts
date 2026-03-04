"use client"

import { useCallback } from "react"
import { useAuth } from "@clerk/nextjs"
import { useRouter } from "next/navigation"

function toSignInUrl(nextPath: string) {
  return `/sign-in?redirect_url=${encodeURIComponent(nextPath)}`
}

export function useRequireAuth() {
  const router = useRouter()
  const { getToken } = useAuth()

  const requireToken = useCallback(
    async (nextPath: string): Promise<string | null> => {
      const token = await getToken()
      if (token) return token

      router.push(toSignInUrl(nextPath))
      return null
    },
    [getToken, router]
  )

  return { requireToken }
}
