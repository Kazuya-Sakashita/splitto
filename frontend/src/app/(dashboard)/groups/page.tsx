"use client"

import { useMemo, useCallback } from "react"
import { useSearchParams, useRouter } from "next/navigation"
import { useGroups } from "@/hooks/useGroups"
import { GroupList } from "./_components/GroupList"
import { GroupEmptyState } from "./_components/GroupEmptyState"
import { Pagination } from "./_components/Pagination"
import { FeedbackPanel } from "@/components/ui/FeedbackPanel"

export default function GroupsPage() {
  const searchParams = useSearchParams()
  const router = useRouter()

  const page = useMemo(() => {
    const raw = searchParams.get("page")
    const n = Number(raw ?? 1)
    if (!Number.isFinite(n) || n < 1) return 1
    return Math.floor(n)
  }, [searchParams])

  // 作成直後のハイライト用（/groups?created=<public_id>）
  const created = searchParams.get("created")

  const { groups, meta, isLoading, error } = useGroups({ page })

  // created は作成直後の一回だけが自然なので、ページ移動時は消す
  const goToPage = useCallback(
    (p: number) => {
      const sp = new URLSearchParams(searchParams.toString())
      sp.set("page", String(p))
      sp.delete("created")
      router.push(`/groups?${sp.toString()}`, { scroll: false })
    },
    [router, searchParams]
  )

  const isEmpty = !isLoading && !error && Array.isArray(groups) && groups.length === 0
  const hasGroups = !isLoading && !error && Array.isArray(groups) && groups.length > 0

  const totalPages = meta?.total_pages ?? 1
  const currentPage = meta?.page ?? page
  const showPagination = hasGroups && totalPages > 1

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="relative mx-auto max-w-4xl px-6 py-10">
        <h1 className="mb-6 text-3xl font-bold">
          グループ一覧 <span className="text-emerald-300">Splitto</span>
        </h1>

        {isLoading && <FeedbackPanel title="読み込み中..." />}

        {error && (
          <FeedbackPanel
            title="取得に失敗しました"
            message={
              error.code === "UNAUTHORIZED"
                ? "ログインが必要です。"
                : "時間をおいて再度お試しください。"
            }
          />
        )}

        {isEmpty && <GroupEmptyState />}

        {hasGroups && (
          <>
            <GroupList groups={groups} highlightedGroupId={created} />

            {showPagination && (
              <Pagination currentPage={currentPage} totalPages={totalPages} onChange={goToPage} />
            )}
          </>
        )}
      </div>
    </main>
  )
}
