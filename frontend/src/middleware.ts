import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server"

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/groups(.*)",
])

export default clerkMiddleware(async (auth, req) => {
  if (!isProtectedRoute(req)) return

  const session = await auth()
  if (!session.userId) {
    return session.redirectToSignIn({ returnBackUrl: req.url })
  }
})

export const config = {
  matcher: ["/((?!.*\\..*|_next).*)", "/", "/(api|trpc)(.*)"],
}
