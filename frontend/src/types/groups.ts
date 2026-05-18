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

export type GroupMemberRole = "OWNER" | "MEMBER"

export type GroupMember = {
  /** Member.public_id（DELETE /groups/:groupId/members/:memberId で使う） */
  public_id: string
  user_id: string
  name: string | null
  role: GroupMemberRole
}

export type GroupDetail = {
  public_id: string
  name: string
  currency: string
  created_at: string | null
  updated_at: string | null
}

export type GroupDetailResponse = {
  group: GroupDetail
  members: GroupMember[]
}
