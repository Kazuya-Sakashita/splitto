import type { ReactNode } from "react"
import type { GroupListItem as GroupDTO } from "@/types/groups"
import { GroupListItem } from "./GroupListItem"
import { GroupEmptyState } from "./GroupEmptyState"
import { toGroupListItemVM } from "../_adapters/groupListItemAdapter"
import { ButtonLink } from "@/components/ui/ButtonLink"

type Props = {
  groups: GroupDTO[]
  title?: string

  /** 右側のアクション。未指定なら「作成リンク」 */
  actions?: ReactNode

  /** actions未指定時のみ使用 */
  createHref?: string
  createLabel?: string

  /** 空表示。未指定ならデフォルトEmptyState */
  empty?: ReactNode

  /** アイテム描画差し替え（必要になった時に効く） */
  renderItem?: (group: GroupDTO) => ReactNode
}

const DEFAULTS = {
  title: "参加中のグループ",
  createHref: "/groups/new",
  createLabel: "グループを作成",
} as const

const styles = {
  section:
    "rounded-3xl border border-white/10 bg-white/5 p-4 shadow-[0_0_0_1px_rgba(255,255,255,0.03)] backdrop-blur",
  list: "mt-2 space-y-3",
  header: "flex items-center justify-between px-2 py-3",
  heading: "text-sm font-semibold text-white/90",
} as const

export function GroupList({
  groups,
  title = DEFAULTS.title,
  actions,
  createHref = DEFAULTS.createHref,
  createLabel = DEFAULTS.createLabel,
  empty,
  renderItem = defaultRenderItem,
}: Props) {
  if (groups.length === 0) {
    return <>{empty ?? <GroupEmptyState />}</>
  }

  return (
    <section className={styles.section}>
      <Header
        title={title}
        right={
          actions ?? (
            <ButtonLink href={createHref} variant="secondary" size="sm">
              {createLabel}
            </ButtonLink>
          )
        }
      />

      <div className={styles.list}>{groups.map(renderItem)}</div>
    </section>
  )
}

function defaultRenderItem(group: GroupDTO) {
  const vm = toGroupListItemVM(group)
  return <GroupListItem key={vm.id} vm={vm} />
}

function Header({ title, right }: { title: string; right: ReactNode }) {
  return (
    <div className={styles.header}>
      <h2 className={styles.heading}>{title}</h2>
      {right}
    </div>
  )
}
