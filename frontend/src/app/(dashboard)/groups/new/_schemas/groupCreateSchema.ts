import { z } from "zod"

export const groupCreateSchema = z.object({
  name: z
    .string()
    .min(1, "グループ名は必須です")
    .max(50, "グループ名は50文字以内にしてください"),
  currency: z
    .string()
    .min(1, "通貨は必須です")
    .max(10, "通貨コードが長すぎます"),
})

export type GroupCreateValues = z.infer<typeof groupCreateSchema>
