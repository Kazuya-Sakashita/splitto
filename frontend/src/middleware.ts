import { clerkMiddleware } from "@clerk/nextjs/server"

export default clerkMiddleware()

export const config = {
  matcher: [
    // Clerk 推奨の基本 matcher
    "/((?!_next|.*\\..*).*)",
    "/(api|trpc)(.*)",
  ],
}
