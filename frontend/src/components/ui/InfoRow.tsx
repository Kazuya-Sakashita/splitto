type InfoRowProps = {
  label: string
  value: string
  accent?: boolean
  className?: string
}

/**
 * ダッシュボード用の情報行
 * - 左：ラベル
 * - 右：値
 */
export function InfoRow({
  label,
  value,
  accent,
  className = "",
}: InfoRowProps) {
  return (
    <div
      className={[
        "flex items-center justify-between gap-4 rounded-2xl",
        "border border-white/10 bg-white/5 px-4 py-3",
        className,
      ].join(" ")}
    >
      <span className="text-sm text-white/70">{label}</span>
      <span
        className={
          accent
            ? "text-sm font-semibold text-emerald-200"
            : "text-sm font-semibold text-white"
        }
      >
        {value}
      </span>
    </div>
  )
}
