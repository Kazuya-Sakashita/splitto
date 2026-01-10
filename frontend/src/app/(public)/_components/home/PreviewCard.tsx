import { GlassCard } from "@/components/ui/GlassCard"
import { SummaryRow } from "@/components/ui/SummaryRow"

export function PreviewCard() {
  return (
    <section className="mx-auto w-full max-w-lg">
      <GlassCard>
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
      </GlassCard>

      <p className="mt-4 text-center text-xs text-white/50">
        © Splitto — Modern Green UI
      </p>
    </section>
  )
}
