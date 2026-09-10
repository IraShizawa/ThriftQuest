# ThriftQuest 実装メモ

## 完成済み

- ホーム画面
- ボス詳細画面
- ボス手入力登録
- 攻略資金追加
- 複数ボスへの分配
- 攻撃結果画面
- 共有から追加画面
- URLから`og:title` / `og:image`候補取得
- カメラ撮影・写真選択
- Vision OCRによる値札の金額候補抽出
- ローカル画像保存
- UserDefaults保存
- App Groups用の共有下書き保存コード
- ActivityKitでLive Activityを開始・更新・終了する本体コード
- Live Activity / Dynamic Island用Widget Extensionソース
- Share Extensionソース

## Xcodeで追加するターゲット

`ThriftQuestShareExtension`と`ThriftQuestWidgetExtension`は、ソースファイルとInfo.plistを配置済みです。
Xcodeの`File > New > Target...`から以下を追加し、既存ファイルをターゲットに含めてください。

### Share Extension

- Target名: `ThriftQuestShareExtension`
- Bundle ID: `app.shizawa.ira.ThriftQuest.ShareExtension`
- 既存フォルダ: `ThriftQuestShareExtension`
- Entitlements: `ThriftQuestShareExtension/ThriftQuestShareExtension.entitlements`
- Info.plist: `ThriftQuestShareExtension/Info.plist`

### Widget Extension

- Target名: `ThriftQuestWidgetExtension`
- Include Live Activity: 有効
- Bundle ID: `app.shizawa.ira.ThriftQuest.WidgetExtension`
- 既存フォルダ: `ThriftQuestWidgetExtension`
- Entitlements: `ThriftQuestWidgetExtension/ThriftQuestWidgetExtension.entitlements`
- Info.plist: `ThriftQuestWidgetExtension/Info.plist`

## App Groups

Apple DeveloperのCapabilitiesで、アプリ本体・Share Extension・Widget Extensionすべてに以下を追加してください。

```text
group.app.shizawa.ira.ThriftQuest
```

## 注意

App Groups、Share Extension、Widget ExtensionはApple Developerの署名設定が必要です。
Codex側では本体アプリのビルド確認まで実施済みです。
