"use client"

import useSWR from "swr"
import type { GroupListResponse } from "@/types/groups"
import { useAuthenticatedFetch } from "@/lib/api/authenticatedFetch"
import { createSWRAuthenticatedFetcher } from "@/lib/api/createSWRAuthenticatedFetcher"
import type { ApiError } from "@/lib/api/problemDetailsError"

type Params = { page?: number }

export function useGroups(params?: Params) {
  const page = params?.page ?? 1
  const authenticatedFetch = useAuthenticatedFetch()

  const key = `/api/v1/groups?page=${page}`

  const fetcher = createSWRAuthenticatedFetcher<GroupListResponse>(
    authenticatedFetch,
    "/api/v1/groups"
  )

  const { data, error, isLoading, mutate } = useSWR<GroupListResponse, ApiError>(
    key,
    () => fetcher({ page }),
    {
      keepPreviousData: true,
      revalidateOnFocus: false,
    }
  )

  return {
    groups: data?.groups ?? [],
    meta: data?.meta ?? null,
    isLoading,
    error: error ?? null,
    mutate,
  }
}
