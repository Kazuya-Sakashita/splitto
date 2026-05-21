"use client"

import { useCallback, useState } from "react"
import { useRouter } from "next/navigation"
import { removeMember } from "@/lib/api/groups"
import type { ApiError } from "@/lib/api/problemDetailsError"
import { useRequireAuth } from "@/hooks/useRequireAuth"

type State = {
  isSubmitting: boolean
  errorMessage: string | null
}

const REASON_MESSAGES: Record<string, string> = {
  cannot_leave_other_member: "自分以外を退出させることはできません。",
  not_group_member: "このグループのメンバーではありません。",
  group_not_found: "グループが見つかりません。",
  member_not_found: "メンバーが見つかりません。",
  owner_cannot_leave: "オーナーはグループから退出できません。",
}

const STATUS_FALLBACKS: Record<number, string> = {
  401: "ログインが必要です。",
  403: "退出する権限がありません。",
  404: "グループまたはメンバーが見つかりません。",
}

function resolveErrorMessage(err: ApiError): string {
  if (err.status === 401 || err.code === "UNAUTHORIZED") {
    return STATUS_FALLBACKS[401]
  }

  const reason = err.problem?.reason
  return (
    (reason && REASON_MESSAGES[reason]) ??
    (err.status !== undefined ? STATUS_FALLBACKS[err.status] : undefined) ??
    "退出に失敗しました。時間をおいて再度お試しください。"
  )
}

export function useLeaveGroupSubmit(groupId: string, memberId: string | null) {
  const router = useRouter()
  const { requireToken } = useRequireAuth()
  const [state, setState] = useState<State>({
    isSubmitting: false,
    errorMessage: null,
  })

  const submit = useCallback(async (): Promise<boolean> => {
    if (!memberId) {
      setState({ isSubmitting: false, errorMessage: "退出対象のメンバーが特定できません。" })
      return false
    }

    setState({ isSubmitting: true, errorMessage: null })

    const token = await requireToken(`/groups/${groupId}`)
    if (!token) {
      setState({ isSubmitting: false, errorMessage: "ログインが必要です。" })
      return false
    }

    try {
      await removeMember(groupId, memberId, { token })
      router.push("/groups")
      router.refresh()
      return true
    } catch (e) {
      const err = e as ApiError
      setState({ isSubmitting: false, errorMessage: resolveErrorMessage(err) })
      return false
    }
  }, [groupId, memberId, requireToken, router])

  return {
    submit,
    isSubmitting: state.isSubmitting,
    errorMessage: state.errorMessage,
  }
}
