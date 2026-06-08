"use client"

import useSWR from "swr"
import type { MeResponse } from "@/types/user"
import { useAuthenticatedFetch } from "@/lib/api/authenticatedFetch"
import { createSWRAuthenticatedFetcher } from "@/lib/api/createSWRAuthenticatedFetcher"
import type { ApiError } from "@/lib/api/problemDetailsError"

export function useMe() {
  const authenticatedFetch = useAuthenticatedFetch()
  const path = "/api/v1/me"

  const fetcher = createSWRAuthenticatedFetcher<MeResponse>(authenticatedFetch, path)

  const { data, error, isLoading, mutate } = useSWR<MeResponse, ApiError>(path, () => fetcher(), {
    revalidateOnFocus: false,
  })

  return {
    me: data?.user ?? null,
    isLoading,
    error: error ?? null,
    mutate,
  }
}
