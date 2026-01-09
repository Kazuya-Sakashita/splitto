import Link from "next/link"
import { SignedIn, SignedOut } from "@clerk/nextjs"
import { SiteHeader } from "./_components/layout/SiteHeader"
import { PreviewCard } from "./_components/home/PreviewCard"
import { HOME_FEATURES } from "./_constants/home"

export default function PublicHomePage() {
  return (
    <div className="mx-auto max-w-6xl px-6 py-12">
      <SiteHeader />

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
            {HOME_FEATURES.map((f) => (
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

        <PreviewCard />
      </main>

      <footer className="mt-14 border-t border-white/10 pt-6 text-center text-xs text-white/50">
        <p>© {new Date().getFullYear()} Splitto</p>
      </footer>
    </div>
  )
}
