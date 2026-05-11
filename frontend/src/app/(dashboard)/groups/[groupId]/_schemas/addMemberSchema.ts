import { z } from "zod"

export const addMemberSchema = z.object({
  user_id: z.string().min(1, "ユーザーIDを入力してください"),
})

export type AddMemberValues = z.infer<typeof addMemberSchema>
