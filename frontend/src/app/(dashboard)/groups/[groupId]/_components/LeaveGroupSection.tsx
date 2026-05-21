"use client"

import { useState, useId, useEffect, useRef } from "react"
import { GlassCard } from "@/components/ui/GlassCard"
import type { GroupMember } from "@/types/groups"
import { useLeaveGroupSubmit } from "../_hooks/useLeaveGroupSubmit"

type Props = {
  groupId: string
  groupName: string
  myMember: GroupMember | null
}

export function LeaveGroupSection({ groupId, groupName, myMember }: Props) {
  const [isDialogOpen, setIsDialogOpen] = useState(false)

  if (!myMember) return null

  const isOwner = myMember.role === "OWNER"

  return (
    <GlassCard className="mt-8 border-rose-500/20 bg-rose-500/[0.04]">
      <h2 className="text-sm font-semibold text-rose-200">危険ゾーン</h2>
      <p className="mt-3 text-sm text-white/70">
        グループから退出すると、このグループのデータにアクセスできなくなります。
        過去の支払い記録は他のメンバーには引き続き表示されます。
      </p>

      {isOwner ? (
        <p className="mt-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-xs text-white/60">
          オーナーはグループから退出できません。
          退出するには、先に他のメンバーにオーナー権限を譲渡してください（今後実装予定）。
        </p>
      ) : (
        <div className="mt-4">
          <button
            type="button"
            onClick={() => setIsDialogOpen(true)}
            className="inline-flex items-center justify-center rounded-full border border-rose-400/30 bg-rose-500/10 px-5 py-2.5 text-sm font-semibold text-rose-100 transition hover:bg-rose-500/20 focus:outline-none focus:ring-2 focus:ring-rose-300/40"
          >
            このグループから退出する
          </button>
        </div>
      )}

      {isDialogOpen && (
        <LeaveGroupConfirmDialog
          groupId={groupId}
          groupName={groupName}
          memberId={myMember.public_id}
          onClose={() => setIsDialogOpen(false)}
        />
      )}
    </GlassCard>
  )
}

type DialogProps = {
  groupId: string
  groupName: string
  memberId: string
  onClose: () => void
}

function LeaveGroupConfirmDialog({ groupId, groupName, memberId, onClose }: DialogProps) {
  const titleId = useId()
  const descId = useId()
  const cancelButtonRef = useRef<HTMLButtonElement>(null)
  const dialogContainerRef = useRef<HTMLDivElement>(null)

  const { submit, isSubmitting, errorMessage } = useLeaveGroupSubmit(groupId, memberId)

  // ダイアログ表示中は背景をスクロール不可に
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
    return () => {
      document.body.style.overflow = previousOverflow
    }
  }, [])

  useEffect(() => {
    cancelButtonRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !isSubmitting) {
        onClose()
        return
      }
      // フォーカストラップ：Tab / Shift+Tab でダイアログ内をループ
      if (e.key === "Tab") {
        const container = dialogContainerRef.current
        if (!container) return
        const focusables = container.querySelectorAll<HTMLElement>(
          'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
        )
        if (focusables.length === 0) return
        const first = focusables[0]
        const last = focusables[focusables.length - 1]
        const active = document.activeElement as HTMLElement | null

        if (e.shiftKey && active === first) {
          e.preventDefault()
          last.focus()
        } else if (!e.shiftKey && active === last) {
          e.preventDefault()
          first.focus()
        }
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [isSubmitting, onClose])

  const handleConfirm = async () => {
    const ok = await submit()
    if (ok) {
      onClose()
    }
  }

  return (
    <div
      ref={dialogContainerRef}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm px-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      aria-describedby={descId}
      onClick={(e) => {
        if (e.target === e.currentTarget && !isSubmitting) onClose()
      }}
    >
      <div className="w-full max-w-md rounded-3xl border border-white/10 bg-neutral-900 p-6 shadow-2xl">
        <h3 id={titleId} className="text-lg font-bold text-white">
          グループから退出しますか？
        </h3>
        <p id={descId} className="mt-3 text-sm text-white/70">
          「{groupName}」から退出します。退出後はこのグループのデータにアクセスできなくなります。
          再参加するには招待リンクが必要です。
        </p>

        {errorMessage && (
          <p
            className="mt-3 rounded-2xl border border-rose-400/30 bg-rose-500/10 px-3 py-2 text-xs text-rose-100"
            role="alert"
          >
            {errorMessage}
          </p>
        )}

        <div className="mt-6 flex justify-end gap-3">
          <button
            ref={cancelButtonRef}
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="inline-flex items-center justify-center rounded-full border border-white/10 bg-white/5 px-5 py-2.5 text-sm font-semibold text-white/80 transition hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-50"
          >
            キャンセル
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={isSubmitting}
            className="inline-flex items-center justify-center rounded-full bg-rose-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-400 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isSubmitting ? "退出中..." : "退出する"}
          </button>
        </div>
      </div>
    </div>
  )
}
