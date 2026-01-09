import Link from "next/link"
import { SignedIn, SignedOut, UserButton } from "@clerk/nextjs"

export function SiteHeader() {
  return (
    <header className="flex items-center justify-between">
      <Brand />

      <nav className="flex items-center gap-3">
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
      </nav>
    </header>
  )
}

function Brand() {
  return (
    <div className="flex items-center gap-3">
      <div className="h-9 w-9 rounded-xl bg-linear-to-br from-emerald-400 to-teal-300 shadow-[0_0_0_1px_rgba(255,255,255,0.10)]" />
      <div className="leading-tight">
        <p className="text-sm font-semibold tracking-wide">Splitto</p>
        <p className="text-xs text-white/60">割り勘・立替精算を、もっとシンプルに。</p>
      </div>
    </div>
  )
}
