export type GroupListItem = {
  public_id: string
  name: string
  currency: string
  updated_at: string
  member_count: number
}

export type PaginationMeta = {
  page: number
  per_page: number
  total_count?: number | null
  total_pages?: number | null
}

export type GroupListResponse = {
  groups: GroupListItem[]
  meta: PaginationMeta
}
