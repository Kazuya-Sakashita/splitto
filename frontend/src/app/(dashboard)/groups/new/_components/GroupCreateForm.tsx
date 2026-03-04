"use client"

import { useCallback } from "react"
import { useForm, type SubmitHandler } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { ButtonLink } from "@/components/ui/ButtonLink"
import { groupCreateSchema, type GroupCreateValues } from "../_schemas/groupCreateSchema"
import { useCreateGroupSubmit } from "../_hooks/useCreateGroupSubmit"

const styles = {
  card: "rounded-3xl border border-white/10 bg-white/5 p-6 shadow-[0_0_0_1px_rgba(255,255,255,0.03)] backdrop-blur",
  field: "mt-5",
  label: "text-sm font-semibold text-white/90",
  input:
    "mt-2 w-full rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-white placeholder:text-white/40 outline-none transition focus:border-emerald-400/40 focus:ring-2 focus:ring-emerald-300/20",
  select:
    "mt-2 w-full rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-white outline-none transition focus:border-emerald-400/40 focus:ring-emerald-300/20",
  help: "mt-2 text-xs text-white/50",
  error: "mt-2 text-xs text-rose-200",
  actions: "mt-6 flex flex-wrap items-center gap-3",
  submit:
    "inline-flex items-center justify-center rounded-full bg-emerald-500 px-6 py-3 text-sm font-semibold text-black transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50",
  notice:
    "mt-4 rounded-2xl border border-white/10 bg-white/5 p-4 text-sm text-white/80",
  disabledLink: "pointer-events-none opacity-50",
} as const

const currencyOptions = [
  { value: "JPY", label: "JPY（円）" },
  { value: "USD", label: "USD（ドル）" },
  { value: "EUR", label: "EUR（ユーロ）" },
] as const

export function GroupCreateForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isValid },
    setError,
  } = useForm<GroupCreateValues>({
    resolver: zodResolver(groupCreateSchema),
    mode: "onChange",
    defaultValues: { name: "", currency: "JPY" },
  })

  const { submit } = useCreateGroupSubmit(setError)

  const onSubmit: SubmitHandler<GroupCreateValues> = useCallback(
    async (values) => {
      await submit(values)
    },
    [submit]
  )

  return (
    <section className={styles.card} aria-label="グループ作成フォーム">
      <form onSubmit={handleSubmit(onSubmit)} noValidate>
        {errors.root?.message ? <div className={styles.notice}>{errors.root.message}</div> : null}

        <div className={styles.field}>
          <label className={styles.label} htmlFor="name">
            グループ名 <span className="text-rose-200">*</span>
          </label>
          <input
            id="name"
            type="text"
            placeholder="例：大阪旅行精算"
            className={styles.input}
            {...register("name")}
            aria-invalid={Boolean(errors.name)}
            disabled={isSubmitting}
          />
          <p className={styles.help}>1〜50文字</p>
          {errors.name?.message ? <p className={styles.error}>{errors.name.message}</p> : null}
        </div>

        <div className={styles.field}>
          <label className={styles.label} htmlFor="currency">
            通貨 <span className="text-rose-200">*</span>
          </label>
          <select
            id="currency"
            className={styles.select}
            {...register("currency")}
            aria-invalid={Boolean(errors.currency)}
            disabled={isSubmitting}
          >
            {currencyOptions.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <p className={styles.help}>未指定の場合、バックエンドではデフォルト（例：JPY）になります</p>
          {errors.currency?.message ? <p className={styles.error}>{errors.currency.message}</p> : null}
        </div>

        <div className={styles.actions}>
          <button type="submit" className={styles.submit} disabled={!isValid || isSubmitting}>
            {isSubmitting ? "作成中..." : "作成する"}
          </button>

          <ButtonLink
            href="/groups"
            variant="secondary"
            size="md"
            className={isSubmitting ? styles.disabledLink : ""}
            ariaLabel="グループ一覧に戻る"
          >
            一覧に戻る
          </ButtonLink>
        </div>
      </form>
    </section>
  )
}
