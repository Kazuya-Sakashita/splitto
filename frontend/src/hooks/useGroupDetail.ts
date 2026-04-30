"use client"

import useSWR from "swr"
import type { GroupDetailResponse } from "@/types/groups"
import { useAuthenticatedFetch } from "@/lib/api/authenticatedFetch"
import { createSWRAuthenticatedFetcher } from "@/lib/api/createSWRAuthenticatedFetcher"
import type { ApiError } from "@/lib/api/problemDetailsError"

export function useGroupDetail(groupId: string) {
  const authenticatedFetch = useAuthenticatedFetch()

  const path = `/api/v1/groups/${encodeURIComponent(groupId)}`

  const fetcher = createSWRAuthenticatedFetcher<GroupDetailResponse>(
    authenticatedFetch,
    path
  )

  const { data, error, isLoading } = useSWR<GroupDetailResponse, ApiError>(
    groupId && /^[1-9A-HJ-NP-Za-km-z]{26}$/.test(groupId) ? path : null,
    () => fetcher(),
    {
      revalidateOnFocus: false,
    }
  )

  return {
    group: data?.group ?? null,
    members: data?.members ?? [],
    isLoading,
    error: error ?? null,
  }
}
