"use client"

import { useAuth } from "@clerk/nextjs"

type FetchArgs = [input: RequestInfo | URL, init?: RequestInit]

/**
 * Clerk の JWT を Authorization ヘッダーに付与して fetch するためのフック。
 *
 * - getToken({ template: "splitto-api" }) を使い、Rails API 用の JWT Template を明示して取得する
 *   （デフォルトトークンだと azp/aud 等が期待とズレて 401 になるケースを避けるため）
 * - init.headers を引き継ぎつつ Authorization を追加する
 * - JSON 送信時のみ Content-Type を付け、FormData の場合はブラウザに任せる
 * - 401 は呼び出し側で一律ハンドリングできるよう例外にする
 */
export function useAuthenticatedFetch() {
  const { getToken } = useAuth()

  return async (...args: FetchArgs) => {
    const [input, init] = args

    // JWT Template を指定して API 用トークンを取得（Clerk Dashboard の Template name と一致させる）
    const token = await getToken({ template: "splitto-api" })

    // 既存ヘッダーを維持しつつ、必要なヘッダーを追加する
    const headers = new Headers(init?.headers)

    // トークンが取得できた場合のみ Authorization を付与（未ログイン時などは付けない）
    if (token) headers.set("Authorization", `Bearer ${token}`)

    // body があるときだけ Content-Type を付ける（GET 等では不要）
    const hasBody = init?.body != null

    // FormData は Content-Type（boundary付き）をブラウザが自動設定するため、手動設定しない
    const isFormData = typeof FormData !== "undefined" && init?.body instanceof FormData

    // JSON 送信時に Content-Type が未指定なら追加（呼び出し側で上書きも可能）
    if (hasBody && !isFormData && !headers.has("Content-Type")) {
      headers.set("Content-Type", "application/json")
    }

    // Bearer 運用では通常 cookie を送らないため credentials は不要（必要になったら追加）
    const res = await fetch(input, {
      ...init,
      headers,
    })

    // 認証失敗は呼び出し側でログイン誘導などに統一して繋げられるよう例外化
    if (res.status === 401) {
      throw new Error("UNAUTHORIZED")
    }

    return res
  }
}
