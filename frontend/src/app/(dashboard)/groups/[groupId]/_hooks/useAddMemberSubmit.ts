"use client"

import { useCallback } from "react"
import type { UseFormSetError } from "react-hook-form"
import { addMember } from "@/lib/api/groups"
import type { ApiError } from "@/lib/api/problemDetailsError"
import { useRequireAuth } from "@/hooks/useRequireAuth"
import type { AddMemberValues } from "../_schemas/addMemberSchema"

export function useAddMemberSubmit(
  groupId: string,
  setError: UseFormSetError<AddMemberValues>,
  onSuccess: () => void
) {
  const { requireToken } = useRequireAuth()

  const submit = useCallback(
    async (values: AddMemberValues): Promise<void> => {
      const token = await requireToken(`/groups/${groupId}`)
      if (!token) {
        setError("root", { type: "server", message: "ログインが必要です。" })
        return
      }

      try {
        await addMember(groupId, { user_id: values.user_id }, { token })
        onSuccess()
      } catch (e) {
        const err = e as ApiError

        if (err.code === "NOT_FOUND") {
          setError("user_id", { type: "server", message: "ユーザーが見つかりません。" })
          return
        }
        if (err.code === "CONFLICT") {
          setError("user_id", { type: "server", message: "すでにメンバーです。" })
          return
        }
        if (err.code === "FORBIDDEN") {
          setError("root", { type: "server", message: "メンバーを追加する権限がありません。" })
          return
        }

        setError("root", { type: "server", message: "追加に失敗しました。時間をおいて再度お試しください。" })
      }
    },
    [groupId, requireToken, setError, onSuccess]
  )

  return { submit }
}
