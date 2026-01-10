"use client"

import { SignOutButton, UserButton } from "@clerk/nextjs"

export function DashboardHeaderActions() {
  return (
    <div className="flex items-center gap-3">
      <UserButton />

      <SignOutButton redirectUrl="/">
        <button
          type="button"
          className="rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10"
        >
          ログアウト
        </button>
      </SignOutButton>
    </div>
  )
}
