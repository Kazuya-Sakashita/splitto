import { GroupCreateForm } from "./_components/GroupCreateForm"

export default function GroupCreatePage() {
  return (
    <main className="min-h-screen bg-black text-white">
      <div className="relative mx-auto max-w-2xl px-6 py-10">
        <header className="mb-6">
          <h1 className="text-3xl font-bold">
            グループ作成 <span className="text-emerald-300">Splitto</span>
          </h1>
          <p className="mt-2 text-sm text-white/70">
            まずはグループ名を入力してください（この画面はUIのみで、API接続は次Issueで対応します）
          </p>
        </header>

        <GroupCreateForm />

        <p className="mt-6 text-xs text-white/50">
          ※ このIssueでは「送信中表示・バリデーション・仮submit」までが対象です
        </p>
      </div>
    </main>
  )
}
