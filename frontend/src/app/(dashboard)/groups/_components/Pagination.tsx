import { useCallback, type ReactNode } from "react"

type Props = {
  currentPage: number
  totalPages: number
  onChange: (page: number) => void
}

const styles = {
  nav: "mt-8 flex items-center justify-center gap-4",
  status: "text-sm text-white/70",
  button:
    "rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm transition hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-40",
} as const

const clamp = (n: number, min: number, max: number) =>
  Math.min(Math.max(n, min), max)

export function Pagination({ currentPage, totalPages, onChange }: Props) {
  // Hooks より前に return しない（Hook順序を固定）
  const safeTotalPages = Number.isFinite(totalPages) ? totalPages : 1
  const page =
    safeTotalPages >= 1 ? clamp(currentPage, 1, safeTotalPages) : 1

  const canPrev = page > 1
  const canNext = page < safeTotalPages

  const goTo = useCallback(
    (nextPage: number) => {
      const next = clamp(nextPage, 1, safeTotalPages)
      if (next !== page) onChange(next)
    },
    [onChange, page, safeTotalPages]
  )

  if (safeTotalPages <= 1) return null

  return (
    <nav className={styles.nav} aria-label="ページネーション">
      <PageButton
        disabled={!canPrev}
        onClick={() => goTo(page - 1)}
        ariaLabel="前のページへ"
      >
        ← 前へ
      </PageButton>

      <span className={styles.status} aria-live="polite">
        {page} / {safeTotalPages}
      </span>

      <PageButton
        disabled={!canNext}
        onClick={() => goTo(page + 1)}
        ariaLabel="次のページへ"
      >
        次へ →
      </PageButton>
    </nav>
  )
}

function PageButton({
  disabled,
  onClick,
  ariaLabel,
  children,
}: {
  disabled: boolean
  onClick: () => void
  ariaLabel: string
  children: ReactNode
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={styles.button}
      aria-label={ariaLabel}
    >
      {children}
    </button>
  )
}
