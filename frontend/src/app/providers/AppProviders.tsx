"use client"

import { useEffect, useRef } from "react"
import { useAuth } from "@clerk/nextjs"
import { SWRConfig, useSWRConfig } from "swr"

/**
 * 認証ユーザー切替時に SWR キャッシュを全廃棄する内部コンポーネント。
 *
 * Issue #48: A でログイン中に取得したキャッシュが、B でログインしたときに
 * 一瞬表示されるのを防ぐ。サーバ側は JWT で常に正しいユーザーのデータを返すが、
 * クライアントの in-memory cache が古い値を保持しているため。
 *
 * mutate(() => true, undefined, { revalidate: false }) で全キーを無効化。
 * 再フェッチは各フックの次回マウント時に走る。
 */
function AuthCacheInvalidator() {
  const { userId, isLoaded } = useAuth()
  const { mutate } = useSWRConfig()
  const prevUserIdRef = useRef<string | null | undefined>(undefined)

  useEffect(() => {
    if (!isLoaded) return

    const prev = prevUserIdRef.current
    const next = userId ?? null

    if (prev === undefined) {
      prevUserIdRef.current = next
      return
    }

    if (prev !== next) {
      if (process.env.NODE_ENV === "development") {
        console.info("[AuthCacheInvalidator] cleared cache", { prev, next })
      }
      mutate(() => true, undefined, { revalidate: false })
      prevUserIdRef.current = next
    }
  }, [isLoaded, userId, mutate])

  return null
}

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <SWRConfig value={{}}>
      <AuthCacheInvalidator />
      {children}
    </SWRConfig>
  )
}
