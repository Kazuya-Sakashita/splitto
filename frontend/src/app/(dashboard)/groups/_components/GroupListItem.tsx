import Link from "next/link"
import { memo } from "react"
import { Badge } from "@/components/ui/Badge"

export type GroupListItemVM = {
  id: string
  name: string
  currency: string
  memberCount: number
  updatedAtLabel: string
}

type Props = {
  vm: GroupListItemVM
}

const styles = {
  link: "group block rounded-2xl border border-white/10 bg-white/5 px-5 py-4 transition hover:border-emerald-400/30 hover:bg-white/10",
  title: "truncate text-base font-semibold text-white/90 group-hover:text-white",
  metaRow: "mt-2 flex flex-wrap items-center gap-2 text-xs text-white/60",
  // 共通Badgeに寄せつつ、見た目を崩さないためにclassNameで上書き
  badge: "rounded-full border border-white/10 bg-black/10 px-2.5 py-1",
  indicatorWrap: "mt-1 flex shrink-0 items-center gap-2",
  dot: "h-2 w-2 rounded-full bg-emerald-400/80 shadow-[0_0_18px_rgba(16,185,129,0.6)]",
  indicatorText: "text-xs font-semibold text-emerald-200/90",
} as const

export const GroupListItem = memo(function GroupListItem({ vm }: Props) {
  return (
    <Link
      href={`/groups/${vm.id}`}
      aria-label={`${vm.name} を開く`}
      className={styles.link}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <Title name={vm.name} />
          <MetaRow
            currency={vm.currency}
            updatedAtLabel={vm.updatedAtLabel}
            memberCount={vm.memberCount}
          />
        </div>

        <Indicator />
      </div>
    </Link>
  )
})

function Title({ name }: { name: string }) {
  return <p className={styles.title}>{name}</p>
}

function MetaRow({
  currency,
  updatedAtLabel,
  memberCount,
}: {
  currency: string
  updatedAtLabel: string
  memberCount: number
}) {
  return (
    <div className={styles.metaRow}>
      <Badge className={styles.badge}>{currency}</Badge>
      <Badge className={styles.badge}>更新: {updatedAtLabel}</Badge>
      <Badge className={styles.badge}>メンバー {memberCount}人</Badge>
    </div>
  )
}

function Indicator() {
  return (
    <div className={styles.indicatorWrap}>
      <span className={styles.dot} />
      <span className={styles.indicatorText}>表示</span>
    </div>
  )
}
