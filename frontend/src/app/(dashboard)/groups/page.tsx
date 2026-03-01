"use client"

import { useMemo, useCallback } from "react"
import { useSearchParams, useRouter } from "next/navigation"
import { useGroups } from "@/hooks/useGroups"
import { GroupList } from "./_components/GroupList"
import { GroupEmptyState } from "./_components/GroupEmptyState"
import { Pagination } from "./_components/Pagination"

export default function GroupsPage() {
  const searchParams = useSearchParams()
  const router = useRouter()

  const page = useMemo(() => {
    const raw = searchParams.get("page")
    const n = Number(raw ?? 1)
    if (!Number.isFinite(n) || n < 1) return 1
    return Math.floor(n)
  }, [searchParams])

  const { groups, meta, isLoading, error } = useGroups({ page })

  const goToPage = useCallback(
    (p: number) => {
      router.push(`/groups?page=${p}`, { scroll: false })
    },
    [router]
  )

  const isEmpty =
    !isLoading && !error && Array.isArray(groups) && groups.length === 0
  const hasGroups =
    !isLoading && !error && Array.isArray(groups) && groups.length > 0

  const totalPages = meta?.total_pages ?? 1
  const currentPage = meta?.page ?? page
  const showPagination = hasGroups && totalPages > 1

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="relative mx-auto max-w-4xl px-6 py-10">
        <h1 className="mb-6 text-3xl font-bold">
          グループ一覧 <span className="text-emerald-300">Splitto</span>
        </h1>

        {isLoading && (
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <p className="text-sm text-white/80">読み込み中...</p>
          </div>
        )}

        {error && (
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <p className="text-sm font-semibold">取得に失敗しました</p>
            <p className="mt-2 text-sm text-white/70">
              {error.message === "UNAUTHORIZED"
                ? "ログインが必要です。"
                : "時間をおいて再度お試しください。"}
            </p>
          </div>
        )}

        {isEmpty && <GroupEmptyState />}

        {hasGroups && (
          <>
            <GroupList groups={groups} />

            {showPagination && (
              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                onChange={goToPage}
              />
            )}
          </>
        )}
      </div>
    </main>
  )
}
