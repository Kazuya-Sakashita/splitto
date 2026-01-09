import type { ReactNode } from "react"

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <main className="min-h-screen bg-linear-to-b from-neutral-950 via-neutral-950 to-neutral-900 text-white">
      {/* 背景のうっすらグリッド */}
      <div className="absolute inset-0 opacity-[0.08] bg-[linear-gradient(to_right,rgba(255,255,255,0.25)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.25)_1px,transparent_1px)] bg-size-[48px_48px]" />

      <div className="relative mx-auto flex min-h-screen max-w-6xl items-center justify-center px-6 py-12">
        <div className="grid w-full items-center gap-10 lg:grid-cols-2">
          {/* 左：Splittoらしいコピー */}
          <section className="hidden lg:block">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-white/80">
              Splitto
              <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-emerald-200">
                beta
              </span>
            </div>

            <h1 className="mt-4 text-4xl font-semibold leading-tight">
              割り勘・立替精算を、
              <span className="block bg-linear-to-r from-emerald-300 to-sky-300 bg-clip-text text-transparent">
                もっとシンプルに
              </span>
            </h1>

            <p className="mt-4 max-w-md text-sm leading-relaxed text-white/70">
              友だち・家族・旅行・飲み会の精算をスムーズに。ログインしてすぐに始められます。
            </p>

            <ul className="mt-6 space-y-3 text-sm text-white/70">
              <li className="flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-300" />
                立替の記録と精算を一元管理
              </li>
              <li className="flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-sky-300" />
                誰がいくら払うかを自動で整理
              </li>
              <li className="flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-violet-300" />
                透明性のある履歴で安心
              </li>
            </ul>
          </section>

          {/* 右：Clerkのカードを“Splittoのカード”に収める */}
          <section className="mx-auto w-full max-w-md">
            <div className="rounded-2xl border border-white/10 bg-white/6 p-6 shadow-[0_0_0_1px_rgba(255,255,255,0.06),0_20px_60px_-20px_rgba(0,0,0,0.7)] backdrop-blur">
              {children}
            </div>

            <p className="mt-4 text-center text-xs text-white/50">
              Secured by Clerk
            </p>
          </section>
        </div>
      </div>
    </main>
  )
}
