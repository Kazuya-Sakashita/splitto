import type { GroupListItem as GroupDTO } from "@/types/groups"
import type { GroupListItemVM } from "@/app/(dashboard)/groups/_components/GroupListItem"

/**
 * DTO → ViewModel 変換（UIからAPI構造を切り離す）
 * - UIはVMのみを扱う
 * - 表示用の軽い整形はここで行う
 */
export const formatDateJaJP = (isoLike: string) => {
  const date = new Date(isoLike)
  return Number.isNaN(date.getTime())
    ? isoLike
    : date.toLocaleDateString("ja-JP")
}

/**
 * GroupListItem用のViewModelを生成する純関数
 * - formatDateは注入可能（テストしやすくするため）
 */
export function toGroupListItemVM(
  dto: GroupDTO,
  formatDate: (value: string) => string = formatDateJaJP
): GroupListItemVM {
  return {
    id: dto.public_id,
    name: dto.name,
    currency: dto.currency,
    memberCount: dto.member_count,
    updatedAtLabel: formatDate(dto.updated_at),
  }
}
