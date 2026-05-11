"use client"

import { useCallback, useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { addMemberSchema, type AddMemberValues } from "../_schemas/addMemberSchema"
import { useAddMemberSubmit } from "../_hooks/useAddMemberSubmit"

const styles = {
  label: "block text-sm font-semibold text-white/90",
  input:
    "mt-2 w-full rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none transition focus:border-emerald-400/40 focus:ring-2 focus:ring-emerald-300/20",
  error: "mt-2 text-xs text-rose-200",
  success: "mt-2 text-xs text-emerald-300",
  notice: "mb-4 rounded-2xl border border-white/10 bg-white/5 p-4 text-sm text-white/80",
  submit:
    "inline-flex items-center justify-center rounded-full bg-emerald-500 px-5 py-2.5 text-sm font-semibold text-black transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50",
} as const

type Props = {
  groupId: string
  onSuccess: () => void
}

export function AddMemberForm({ groupId, onSuccess }: Props) {
  const [succeeded, setSucceeded] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting, isValid },
    setError,
  } = useForm<AddMemberValues>({
    resolver: zodResolver(addMemberSchema),
    mode: "onChange",
    defaultValues: { user_id: "" },
  })

  const handleSuccess = useCallback(() => {
    reset()
    setSucceeded(true)
    onSuccess()
  }, [reset, onSuccess])

  const { submit } = useAddMemberSubmit(groupId, setError, handleSuccess)

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="mt-4 flex flex-col gap-3">
      {errors.root?.message && <p className={styles.notice}>{errors.root.message}</p>}
      <div>
        <label htmlFor="user_id" className={styles.label}>
          ユーザーID
        </label>
        <input
          id="user_id"
          type="text"
          placeholder="例：3yKqJ7mNpX2aRvL8tWdF4eUhC1"
          className={styles.input}
          {...register("user_id")}
          aria-invalid={Boolean(errors.user_id)}
          disabled={isSubmitting}
        />
        {errors.user_id?.message && <p className={styles.error}>{errors.user_id.message}</p>}
        {succeeded && !errors.user_id && (
          <p className={styles.success}>メンバーを追加しました。</p>
        )}
      </div>
      <div>
        <button type="submit" className={styles.submit} disabled={!isValid || isSubmitting}>
          {isSubmitting ? "追加中..." : "メンバーを追加"}
        </button>
      </div>
    </form>
  )
}
