export function PreviewCard() {
  return (
    <section className="mx-auto w-full max-w-lg">
      <div className="rounded-3xl border border-white/10 bg-white/6 p-6 shadow-[0_0_0_1px_rgba(255,255,255,0.06),0_20px_60px_-20px_rgba(0,0,0,0.7)] backdrop-blur">
        <div className="rounded-2xl bg-linear-to-br from-emerald-500/20 via-teal-400/10 to-lime-300/10 p-5">
          <p className="text-sm font-semibold">サンプル：精算のイメージ</p>
          <p className="mt-1 text-xs text-white/60">
            あとでダッシュボード実装に合わせて置き換え予定でOK
          </p>

          <div className="mt-5 space-y-3 text-sm">
            <SummaryRow label="合計" value="¥12,300" />
            <SummaryRow label="あなた" value="¥3,200" />
            <SummaryRow label="未精算" value="¥1,800" accent />
          </div>

          <div className="mt-6 flex gap-3">
            <button
              type="button"
              className="flex-1 rounded-2xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-neutral-950 hover:bg-emerald-400"
            >
              立替を追加
            </button>

            <button
              type="button"
              className="flex-1 rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10"
            >
              メンバーを見る
            </button>
          </div>
        </div>
      </div>

      <p className="mt-4 text-center text-xs text-white/50">
        © Splitto — Modern Green UI
      </p>
    </section>
  )
}

function SummaryRow({
  label,
  value,
  accent,
}: {
  label: string
  value: string
  accent?: boolean
}) {
  return (
    <div className="flex items-center justify-between rounded-xl border border-white/10 bg-white/5 px-4 py-3">
      <span className="text-white/70">{label}</span>
      <span
        className={accent ? "font-semibold text-emerald-200" : "font-semibold text-white"}
      >
        {value}
      </span>
    </div>
  )
}
