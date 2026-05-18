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

function resolveErrorMessage(err: ApiError): string {
  if (err.status === 401 || err.code === "UNAUTHORIZED") {
    return "ログインが必要です。"
  }

  const reason = err.problem?.reason

  if (err.status === 403) {
    if (reason === "cannot_leave_other_member") return "自分以外を退出させることはできません。"
    if (reason === "not_group_member") return "このグループのメンバーではありません。"
    return "退出する権限がありません。"
  }

  if (err.status === 404) {
    if (reason === "group_not_found") return "グループが見つかりません。"
    if (reason === "member_not_found") return "メンバーが見つかりません。"
    return "グループまたはメンバーが見つかりません。"
  }

  if (err.status === 422 && reason === "owner_cannot_leave") {
    return "オーナーはグループから退出できません。"
  }

  return "退出に失敗しました。時間をおいて再度お試しください。"
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
