import { currentUser } from "@clerk/nextjs/server"
import { redirect } from "next/navigation"
import { DashboardHeaderActions } from "./_components/DashboardHeaderActions"
import { GlassCard } from "@/components/ui/GlassCard"
import { InfoRow } from "@/components/ui/InfoRow"
import { Badge } from "@/components/ui/Badge"

export default async function DashboardPage() {
  const user = await currentUser()
  if (!user) redirect("/sign-in")

  const primaryEmail = user.emailAddresses?.[0]?.emailAddress ?? "-"
  const name =
    [user.firstName, user.lastName].filter(Boolean).join(" ") ||
    user.username ||
    "ユーザー"

  return (
    <div className="mx-auto max-w-5xl px-6 py-10">
      {/* Header */}
      <header className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge>Splitto Dashboard</Badge>
            <Badge tone="emerald">signed in</Badge>
          </div>

          <h1 className="mt-3 text-2xl font-semibold tracking-tight sm:text-3xl">
            こんにちは、{name} さん
          </h1>

          <p className="mt-2 text-sm text-white/60">
            ログインが完了しました。ここから精算の管理を始めましょう。
          </p>
        </div>

        <DashboardHeaderActions />
      </header>

      {/* Content */}
      <main className="mt-10">
        <GlassCard>
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-base font-semibold">ログイン情報（Clerk）</h2>
              <p className="mt-1 text-xs text-white/60">
                ユーザー情報が表示されていれば、ログインは成功です。
              </p>
            </div>

            <div className="h-10 w-10 rounded-2xl bg-linear-to-br from-emerald-400 to-teal-300 shadow-[0_0_0_1px_rgba(255,255,255,0.10)]" />
          </div>

          <div className="mt-6 grid gap-3">
            <InfoRow label="User ID" value={user.id} />
            <InfoRow label="Name" value={name} />
            <InfoRow label="Email" value={primaryEmail} />
          </div>
        </GlassCard>
      </main>
    </div>
  )
}
