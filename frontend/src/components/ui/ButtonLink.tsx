import Link from "next/link"
import type { ReactNode } from "react"

export type ButtonLinkVariant = "primary" | "secondary" | "ghost"
export type ButtonLinkSize = "sm" | "md"

type Props = {
  href: string
  children: ReactNode
  variant?: ButtonLinkVariant
  size?: ButtonLinkSize
  className?: string
  ariaLabel?: string
}

const base =
  "inline-flex items-center justify-center rounded-full font-semibold transition focus:outline-none focus:ring-2 focus:ring-offset-0"

const sizes: Record<ButtonLinkSize, string> = {
  sm: "px-4 py-2 text-xs",
  md: "px-6 py-3 text-sm",
}

const variants: Record<ButtonLinkVariant, string> = {
  primary:
    "bg-emerald-500 text-black hover:bg-emerald-400 focus:ring-emerald-300/60",
  secondary:
    "border border-white/10 bg-white/5 text-white/80 hover:bg-white/10 focus:ring-white/20",
  ghost: "text-white/70 hover:text-white hover:bg-white/10 focus:ring-white/20",
}

export function ButtonLink({
  href,
  children,
  variant = "secondary",
  size = "md",
  className,
  ariaLabel,
}: Props) {
  return (
    <Link
      href={href}
      aria-label={ariaLabel}
      className={[base, sizes[size], variants[variant], className]
        .filter(Boolean)
        .join(" ")}
    >
      {children}
    </Link>
  )
}
