import type { ReactNode } from "react"

type BadgeProps = {
  children: ReactNode
  tone?: "default" | "emerald"
  size?: "sm" | "md"
  className?: string
}

/**
 * ステータス・ラベル表示用のバッジ
 * 例: "signed in", "beta", "splitto"
 */
export function Badge({
  children,
  tone = "default",
  size = "sm",
  className = "",
}: BadgeProps) {
  const base =
    "inline-flex items-center gap-2 rounded-full border font-medium"

  const sizes = {
    sm: "px-3 py-1 text-xs",
    md: "px-4 py-1.5 text-sm",
  } as const

  const tones = {
    default: "border-white/10 bg-white/5 text-white/80",
    emerald: "border-emerald-400/20 bg-emerald-500/15 text-emerald-200",
  } as const

  return (
    <span
      className={[
        base,
        sizes[size],
        tones[tone],
        className,
      ].join(" ")}
    >
      {children}
    </span>
  )
}
