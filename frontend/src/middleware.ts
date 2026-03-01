import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server"

// 公開OKなページだけ列挙（それ以外はデフォルトで認証必須）
const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
])

export default clerkMiddleware(async (auth, req) => {
  if (isPublicRoute(req)) return

  const session = await auth()
  if (!session.userId) {
    return session.redirectToSignIn({ returnBackUrl: req.url })
  }
})

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
}
