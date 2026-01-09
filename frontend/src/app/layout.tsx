import type { Metadata } from "next"
import { ClerkProvider } from "@clerk/nextjs"
import "./globals.css"

export const metadata: Metadata = {
  title: {
    default: "Splitto",
    template: "%s | Splitto",
  },
  description: "割り勘・立替精算を、もっとシンプルに。",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <ClerkProvider
      appearance={{
        variables: {
          // Splitto: modern green
          colorPrimary: "#10b981", // emerald-500
          colorText: "#ffffff",
          colorBackground: "transparent",
        },
        elements: {
          // Clerk UI をアプリのカードに馴染ませる
          card: "bg-transparent shadow-none border-0",
          headerTitle: "text-white",
          headerSubtitle: "text-white/60",
          socialButtonsBlockButton:
            "bg-white/5 border border-white/10 text-white hover:bg-white/10",
          formButtonPrimary:
            "bg-emerald-500 text-neutral-950 hover:bg-emerald-400",
          formFieldInput:
            "bg-white/5 border-white/10 text-white placeholder:text-white/40 focus:ring-emerald-400/40",
          footerActionLink: "text-emerald-300 hover:text-emerald-200",
        },
      }}
    >
      <html lang="ja" suppressHydrationWarning>
        <body className="min-h-screen text-white antialiased">
          {/* グローバル背景（全ページ共通） */}
          <div className="relative min-h-screen bg-neutral-950">
            {/* light blobs */}
            <div className="pointer-events-none absolute inset-0">
              <div className="absolute -top-44 left-1/2 h-140 w-140 -translate-x-1/2 rounded-full bg-emerald-500/22 blur-3xl" />
              <div className="absolute -bottom-60 -right-35 h-140 w-140 rounded-full bg-teal-400/18 blur-3xl" />
              <div className="absolute top-24 -left-40 h-105 w-105 rounded-full bg-lime-300/10 blur-3xl" />

              {/* subtle grid */}
              <div className="absolute inset-0 opacity-[0.08] bg-[linear-gradient(to_right,rgba(255,255,255,0.25)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.25)_1px,transparent_1px)] bg-size-[48px_48px]" />

              {/* depth */}
              <div className="absolute inset-0 bg-linear-to-b from-black/0 via-black/10 to-black/35" />
            </div>

            {/* content */}
            <div className="relative min-h-screen">{children}</div>
          </div>
        </body>
      </html>
    </ClerkProvider>
  )
}
