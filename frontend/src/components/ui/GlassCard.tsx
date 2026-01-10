import type { ReactNode } from "react"

type GlassCardProps = {
  children: ReactNode
  className?: string
}

/**
 * Splitto 共通のガラス調カード
 * - public / dashboard / preview で再利用
 */
export function GlassCard({ children, className = "" }: GlassCardProps) {
  return (
    <div
      className={[
        "rounded-3xl border border-white/10 bg-white/6 p-6",
        "shadow-[0_0_0_1px_rgba(255,255,255,0.06),0_20px_60px_-20px_rgba(0,0,0,0.7)]",
        "backdrop-blur",
        className,
      ].join(" ")}
    >
      {children}
    </div>
  )
}
