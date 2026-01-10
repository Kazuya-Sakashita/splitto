type SummaryRowProps = {
  label: string
  value: string
  accent?: boolean
  className?: string
}

/**
 * 精算サマリー表示用の行コンポーネント
 * - PreviewCard 等で「合計/あなた/未精算」などの数値を見せる用途
 */
export function SummaryRow({
  label,
  value,
  accent,
  className = "",
}: SummaryRowProps) {
  return (
    <div
      className={[
        "flex items-center justify-between rounded-xl border border-white/10 bg-white/5 px-4 py-3",
        className,
      ].join(" ")}
    >
      <span className="text-white/70">{label}</span>
      <span
        className={
          accent ? "font-semibold text-emerald-200" : "font-semibold text-white"
        }
      >
        {value}
      </span>
    </div>
  )
}
