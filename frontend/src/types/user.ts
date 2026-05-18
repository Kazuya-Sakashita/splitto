export type ThemeMode = "SYSTEM" | "LIGHT" | "DARK"

export type Me = {
  id: number
  public_id: string
  external_uid: string
  name: string | null
  email: string | null
  notify_email: boolean | null
  theme_mode: ThemeMode | null
  created_at: string | null
  updated_at: string | null
}

export type MeResponse = {
  user: Me
}
