import Link from "next/link"
import { SignedIn, SignedOut, UserButton } from "@clerk/nextjs"

export default function HomePage() {
  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      {/* Header */}
      <header className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-xl bg-linear-to-br from-emerald-400 to-teal-300 shadow-[0_0_0_1px_rgba(255,255,255,0.10)]" />
          <div>
            <p className="text-sm font-semibold tracking-wide">Splitto</p>
            <p className="text-xs text-white/60">割り勘・立替精算を、もっとシンプルに。</p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <SignedOut>
            <Link
              href="/sign-in"
              className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10"
            >
              ログイン
            </Link>
            <Link
              href="/sign-up"
              className="rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-neutral-950 hover:bg-emerald-400"
            >
              新規登録
            </Link>
          </SignedOut>

          <SignedIn>
            <Link
              href="/dashboard"
              className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10"
            >
              ダッシュボード
            </Link>
            <UserButton />
          </SignedIn>
        </div>
      </header>

      {/* Hero */}
      <main className="mt-14 grid gap-10 lg:grid-cols-2 lg:items-center">
        <section>
          <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-white/80">
            Modern Green UI
            <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-emerald-200">
              splitto
            </span>
          </div>

          <h1 className="mt-5 text-4xl font-semibold leading-tight lg:text-5xl">
            精算のモヤモヤを、
            <span className="block bg-linear-to-r from-emerald-300 via-teal-200 to-lime-200 bg-clip-text text-transparent">
              透明に、スマートに。
            </span>
          </h1>

          <p className="mt-4 max-w-xl text-sm leading-relaxed text-white/70">
            旅行・飲み会・家計の立替など、面倒な計算をまとめて管理。
            誰がいくら払うかを整理して、スムーズに精算できます。
          </p>

          <div className="mt-7 flex flex-wrap gap-3">
            <SignedOut>
              <Link
                href="/sign-up"
                className="rounded-2xl bg-emerald-500 px-5 py-3 text-sm font-semibold text-neutral-950 hover:bg-emerald-400"
              >
                無料ではじめる
              </Link>
              <Link
                href="/sign-in"
                className="rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm text-white hover:bg-white/10"
              >
                ログイン
              </Link>
            </SignedOut>

            <SignedIn>
              <Link
                href="/dashboard"
                className="rounded-2xl bg-emerald-500 px-5 py-3 text-sm font-semibold text-neutral-950 hover:bg-emerald-400"
              >
                ダッシュボードへ
              </Link>
            </SignedIn>
          </div>

          <div className="mt-8 grid gap-3 sm:grid-cols-3">
            {[
              { title: "立替を記録", desc: "支払いをサクッと登録" },
              { title: "自動で整理", desc: "支払う人を明確に" },
              { title: "履歴で安心", desc: "あとから見返せる" },
            ].map((f) => (
              <div
                key={f.title}
                className="rounded-2xl border border-white/10 bg-white/6 p-4 backdrop-blur"
              >
                <p className="text-sm font-semibold">{f.title}</p>
                <p className="mt-1 text-xs text-white/60">{f.desc}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Right card */}
        <section className="mx-auto w-full max-w-lg">
          <div className="rounded-3xl border border-white/10 bg-white/6 p-6 shadow-[0_0_0_1px_rgba(255,255,255,0.06),0_20px_60px_-20px_rgba(0,0,0,0.7)] backdrop-blur">
            <div className="rounded-2xl bg-linear-to-br from-emerald-500/20 via-teal-400/10 to-lime-300/10 p-5">
              <p className="text-sm font-semibold">サンプル：精算のイメージ</p>
              <p className="mt-1 text-xs text-white/60">
                あとでダッシュボード実装に合わせて置き換え予定でOK
              </p>

              <div className="mt-5 space-y-3 text-sm">
                <Row label="合計" value="¥12,300" />
                <Row label="あなた" value="¥3,200" />
                <Row label="未精算" value="¥1,800" accent />
              </div>

              <div className="mt-6 flex gap-3">
                <button className="flex-1 rounded-2xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-neutral-950 hover:bg-emerald-400">
                  立替を追加
                </button>
                <button className="flex-1 rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10">
                  メンバーを見る
                </button>
              </div>
            </div>
          </div>

          <p className="mt-4 text-center text-xs text-white/50">
            © Splitto — Modern Green UI
          </p>
        </section>
      </main>
    </div>
  )
}

function Row({
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
        className={
          accent
            ? "font-semibold text-emerald-200"
            : "font-semibold text-white"
        }
      >
        {value}
      </span>
    </div>
  )
}
