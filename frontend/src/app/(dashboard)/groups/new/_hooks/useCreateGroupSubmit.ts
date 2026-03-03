"use client"

import { useCallback } from "react"
import { useRouter } from "next/navigation"
import type { UseFormSetError } from "react-hook-form"
import { createGroup } from "@/lib/api/groups"
import type { CreateGroupPayload } from "@/lib/api/groups"
import type { ApiError } from "@/lib/api/problemDetailsError"
import { useRequireAuth } from "@/hooks/useRequireAuth"
import type { GroupCreateValues } from "../_schemas/groupCreateSchema"

function buildCreateGroupPayload(values: GroupCreateValues): CreateGroupPayload {
  return {
    group: {
      name: values.name,
      currency: values.currency,
    },
  }
}

function getFirstErrorMessage(v: unknown): string | null {
  if (!v) return null
  if (Array.isArray(v)) return v.length > 0 ? String(v[0]) : null
  return String(v)
}

export function useCreateGroupSubmit(setError: UseFormSetError<GroupCreateValues>) {
  const router = useRouter()
  const { requireToken } = useRequireAuth()

  const submit = useCallback(
    async (values: GroupCreateValues): Promise<void> => {
      const token = await requireToken("/groups/new")
      if (!token) {
        setError("root", { type: "server", message: "ログインが必要です。" })
        return
      }

      try {
        const payload = buildCreateGroupPayload(values)
        const res = await createGroup(payload, { token })
        const createdId = res.group.public_id

        router.push(`/groups?created=${encodeURIComponent(createdId)}`)
        router.refresh()
      } catch (e) {
        const err = e as ApiError

        if (err.code === "UNAUTHORIZED") {
          setError("root", { type: "server", message: "ログインが必要です。" })
          return
        }

        if (err.status === 422 && err.problem?.errors) {
          const pe = err.problem.errors as Record<string, unknown>

          const nameMsg = getFirstErrorMessage(pe["name"])
          const currencyMsg = getFirstErrorMessage(pe["currency"])

          if (nameMsg) setError("name", { type: "server", message: nameMsg })
          if (currencyMsg) setError("currency", { type: "server", message: currencyMsg })

          if (!nameMsg && !currencyMsg) {
            setError("root", {
              type: "server",
              message: err.problem.detail ?? "入力内容を確認してください。",
            })
          }
          return
        }

        setError("root", {
          type: "server",
          message: err.problem?.detail ?? "作成に失敗しました。",
        })
      }
    },
    [requireToken, router, setError]
  )

  return { submit }
}
