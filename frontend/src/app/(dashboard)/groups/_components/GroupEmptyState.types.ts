import type { ButtonLinkSize, ButtonLinkVariant } from "@/components/ui/ButtonLink"

export type ActionItem = {
  href: string
  label: string
  variant?: ButtonLinkVariant
  size?: ButtonLinkSize
  hidden?: boolean
}

export type GroupEmptyStateProps = {
  title?: string
  description?: string

  primaryHref?: string
  primaryLabel?: string
  secondaryHref?: string
  secondaryLabel?: string

  actions?: ActionItem[]
  showDevNote?: boolean
  devNoteText?: string
}
