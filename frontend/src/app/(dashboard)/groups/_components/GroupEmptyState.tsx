import type { ActionItem, GroupEmptyStateProps as Props } from "./GroupEmptyState.types"
import { ButtonLink } from "@/components/ui/ButtonLink"

const DEFAULTS = {
  title: "参加しているグループがありません",
  description:
    "まずはグループを作成して、メンバーと一緒に立替や精算を管理しましょう。作成画面は後続Issueで実装予定でも、導線だけ先に置いてOKです。",
  primaryHref: "/groups/new",
  primaryLabel: "グループを作成する",
  secondaryHref: "/",
  secondaryLabel: "ホームに戻る",
  devNoteText: "※ 作成画面が未実装の場合は後続Issueで接続します",
} as const

const styles = {
  section:
    "rounded-3xl border border-white/10 bg-white/5 p-8 shadow-[0_0_0_1px_rgba(255,255,255,0.03)] backdrop-blur",
  title: "text-lg font-semibold text-white/90",
  description: "mt-2 whitespace-pre-line text-sm leading-relaxed text-white/70",
  actions: "flex flex-wrap items-center gap-3",
  devNote: "text-xs text-white/50",
} as const

function shouldShowDevNote(explicit?: boolean) {
  return explicit ?? process.env.NODE_ENV !== "production"
}

function buildDefaultActions(
  primaryHref?: string,
  primaryLabel?: string,
  secondaryHref?: string,
  secondaryLabel?: string
): ActionItem[] {
  const actions: ActionItem[] = []

  if (primaryHref && primaryLabel) {
    actions.push({ href: primaryHref, label: primaryLabel, variant: "primary" })
  }

  if (secondaryHref && secondaryLabel) {
    actions.push({
      href: secondaryHref,
      label: secondaryLabel,
      variant: "secondary",
    })
  }

  return actions
}

export function GroupEmptyState({
  title = DEFAULTS.title,
  description = DEFAULTS.description,
  primaryHref = DEFAULTS.primaryHref,
  primaryLabel = DEFAULTS.primaryLabel,
  secondaryHref = DEFAULTS.secondaryHref,
  secondaryLabel = DEFAULTS.secondaryLabel,
  actions,
  showDevNote,
  devNoteText = DEFAULTS.devNoteText,
}: Props) {
  const resolvedActions =
    actions?.length
      ? actions
      : buildDefaultActions(primaryHref, primaryLabel, secondaryHref, secondaryLabel)

  const visibleActions = resolvedActions.filter((a) => !a.hidden)
  const showNote = shouldShowDevNote(showDevNote)

  return (
    <section className={styles.section}>
      <div className="flex flex-col items-start gap-6">
        <div>
          <p className={styles.title}>{title}</p>
          <p className={styles.description}>{description}</p>
        </div>

        {(visibleActions.length > 0 || showNote) && (
          <div className={styles.actions}>
            {visibleActions.map((a) => (
              <ButtonLink
                key={`${a.href}:${a.label}`}
                href={a.href}
                variant={a.variant ?? "secondary"}
                size={a.size ?? "md"}
              >
                {a.label}
              </ButtonLink>
            ))}

            {showNote && <span className={styles.devNote}>{devNoteText}</span>}
          </div>
        )}

        <Accent />
      </div>
    </section>
  )
}

function Accent() {
  return (
    <div className="ml-auto h-10 w-10 rounded-2xl bg-[radial-gradient(circle_at_30%_30%,rgba(16,185,129,0.55),transparent_65%)] shadow-[0_0_40px_rgba(16,185,129,0.35)]" />
  )
}
