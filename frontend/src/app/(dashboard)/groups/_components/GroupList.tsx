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

  /**
   * 作成直後に一覧で「これを作った」が分かるようにハイライトするID
   * 例: /groups?created=<public_id> の created
   */
  highlightedGroupId?: string | null
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

  // ✅ 追加
  banner:
    "mb-3 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white/80",
  highlightWrapper: "rounded-2xl ring-2 ring-emerald-300/30",
} as const

export function GroupList({
  groups,
  title = DEFAULTS.title,
  actions,
  createHref = DEFAULTS.createHref,
  createLabel = DEFAULTS.createLabel,
  empty,
  renderItem,
  highlightedGroupId,
}: Props) {
  if (groups.length === 0) {
    return <>{empty ?? <GroupEmptyState />}</>
  }

  // ✅ 作成直後のバナーは「該当が一覧内に存在する」時だけ出す
  const createdGroupName =
    highlightedGroupId ? groups.find((g) => g.public_id === highlightedGroupId)?.name : null

  const render = renderItem ?? makeDefaultRenderItem(highlightedGroupId)

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

      {createdGroupName ? (
        <div className={styles.banner}>「{createdGroupName}」を作成しました</div>
      ) : null}

      <div className={styles.list}>{groups.map(render)}</div>
    </section>
  )
}

/**
 * defaultRenderItem は highlightedGroupId を扱えるように factory 化
 * - renderItem を差し替えた場合は、呼び出し側で好きな見せ方にできる
 */
function makeDefaultRenderItem(highlightedGroupId?: string | null) {
  return function defaultRenderItem(group: GroupDTO) {
    const vm = toGroupListItemVM(group)
    const isHighlighted = highlightedGroupId != null && group.public_id === highlightedGroupId

    const item = <GroupListItem key={vm.id} vm={vm} />

    // ✅ 既存の GroupListItem を壊さず “外側で” ハイライト
    return isHighlighted ? (
      <div key={vm.id} className={styles.highlightWrapper}>
        {item}
      </div>
    ) : (
      item
    )
  }
}

function Header({ title, right }: { title: string; right: ReactNode }) {
  return (
    <div className={styles.header}>
      <h2 className={styles.heading}>{title}</h2>
      {right}
    </div>
  )
}
