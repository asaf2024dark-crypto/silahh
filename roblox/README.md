# Silah Sistemi Düzeltme Notları

Bu klasör, decompiler ile bozulan modüllerin temizlenmiş sürümlerini içerir.

## Yerleşim
- `ReplicatedStorage/SilahTA/SilahModules`
  - `ModuleComponents.lua`
  - `OtherFunctions.lua`
  - `RemoteEvents.lua`
  - `TakimKurallari.lua`
  - `spring.lua`
- `ServerScriptService/SilahTA`
  - `BanService.lua`
  - `WeaponServer.server.lua`

## Önemli
- `WeaponServer.server.lua` hasarı **server-authoritative** işler.
- Client sadece hedef bilgisi gönderir; raycast ve hasar server tarafında doğrulanır.
