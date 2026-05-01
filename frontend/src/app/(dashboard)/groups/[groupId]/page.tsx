"use client"

import { use } from "react"
import Link from "next/link"
import { useGroupDetail } from "@/hooks/useGroupDetail"
import { GlassCard } from "@/components/ui/GlassCard"
import { InfoRow } from "@/components/ui/InfoRow"
import { Badge } from "@/components/ui/Badge"
import { FeedbackPanel } from "@/components/ui/FeedbackPanel"
import { AddMemberForm } from "./_components/AddMemberForm"

type Props = {
  params: Promise<{ groupId: string }>
}

export default function GroupDetailPage({ params }: Props) {
  const { groupId } = use(params)
  const { group, members, isLoading, error, mutate } = useGroupDetail(groupId)

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="relative mx-auto max-w-4xl px-6 py-10">

        <div className="mb-6">
          <Link
            href="/groups"
            className="text-sm text-white/50 hover:text-white/80 transition"
          >
            ← グループ一覧に戻る
          </Link>
        </div>

        {isLoading && <FeedbackPanel title="読み込み中..." />}

        {error && (
          <FeedbackPanel
            title="エラー"
            message={
              error.code === "NOT_FOUND"
                ? "グループが見つかりません。"
                : error.code === "FORBIDDEN"
                  ? "このグループへのアクセス権限がありません。"
                  : error.code === "UNAUTHORIZED"
                    ? "ログインが必要です。"
                    : "取得に失敗しました。時間をおいて再度お試しください。"
            }
          />
        )}

        {group && (
          <>
            <h1 className="mb-6 text-3xl font-bold">{group.name}</h1>

            <GlassCard className="mb-8">
              <h2 className="mb-4 text-sm font-semibold text-white/90">グループ情報</h2>
              <div className="space-y-2">
                <InfoRow label="通貨" value={group.currency} />
                <InfoRow
                  label="作成日"
                  value={group.created_at ? new Date(group.created_at).toLocaleDateString("ja-JP") : "—"}
                />
                <InfoRow
                  label="更新日"
                  value={group.updated_at ? new Date(group.updated_at).toLocaleDateString("ja-JP") : "—"}
                />
              </div>
            </GlassCard>

            <GlassCard>
              <div className="flex items-center justify-between px-2 py-3">
                <h2 className="text-sm font-semibold text-white/90">
                  メンバー ({members.length}人)
                </h2>
              </div>

              <AddMemberForm groupId={groupId} onSuccess={mutate} />

              <ul className="mt-4 space-y-3">
                {members.map((member) => (
                  <li
                    key={member.user_id}
                    className="flex items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-5 py-4"
                  >
                    <span className="text-sm text-white/80">{member.name ?? member.user_id}</span>
                    <Badge tone={member.role === "OWNER" ? "emerald" : "default"}>
                      {member.role}
                    </Badge>
                  </li>
                ))}
              </ul>
            </GlassCard>
          </>
        )}

      </div>
    </main>
  )
}
