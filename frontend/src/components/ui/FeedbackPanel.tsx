type FeedbackPanelProps = {
  title: string
  message?: string
}

export function FeedbackPanel({ title, message }: FeedbackPanelProps) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
      <p className="text-sm font-semibold">{title}</p>
      {message && (
        <p className="mt-2 text-sm text-white/70">{message}</p>
      )}
    </div>
  )
}
