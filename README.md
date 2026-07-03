# Animate

A Roblox experience built with [Rojo](https://github.com/rojo-rbx/rojo), [Wally](https://wally.run/), and [Knit](https://github.com/Sleitnick/Knit).

## Toolchain

Tools are pinned in `rokit.toml` and installed with [Rokit](https://github.com/rojo-rbx/rokit):

```bash
rokit install
```

This gets you `rojo`, `wally`, `selene` (linter), and `stylua` (formatter).

## Getting Started

Install dependencies, then build and open the place:

```bash
wally install
rojo build -o "Animate.rbxlx"
```

Open `Animate.rbxlx` in Roblox Studio, then start the live sync server:

```bash
rojo serve
```

## Project Structure

```
src/
  server/
    init.server.luau        -- requires + starts all Services, boots Knit
    Services/                -- one ModuleScript per server-side feature
      ExampleService.luau
  client/
    init.client.luau        -- requires + starts all Controllers, boots Knit
    Controllers/             -- one ModuleScript per client-side feature
      ExampleController.luau
  shared/
    Constants.luau           -- shared constant values
    Types/                    -- shared Luau type exports
```

- **Services** (server) and **Controllers** (client) are [Knit](https://github.com/Sleitnick/Knit) modules. Add a new feature by dropping a new file in `Services/` or `Controllers/` — it's picked up automatically.
- **`src/shared`** syncs to `ReplicatedStorage.Shared` and holds code/data used by both client and server (constants, types, pure utility modules).
- Client-exposed Service methods go under `Client = { ... }` in a Service; call them from a Controller via `Knit.GetService("Name")`.

## Dependencies (Wally)

Declared in `wally.toml`, locked in `wally.lock` (committed), installed into `Packages/` (gitignored — restore with `wally install`).

- **Knit** — service/controller framework tying client and server together.
- **TestEZ** *(dev dependency)* — spec-style unit testing.

To add a library, add it to `wally.toml` under `[dependencies]` (shared) or `[server-dependencies]` (server-only), then run `wally install`. Shared packages sync into `ReplicatedStorage.Packages`; if you add server-only deps, add a matching `"ServerPackages": { "$path": "ServerPackages" }` entry under `ServerStorage` in `default.project.json`.

Worth considering as the project grows:
- [Signal](https://github.com/Sleitnick/RbxUtil) / [Promise](https://github.com/evaera/roblox-lua-promise) — already pulled in transitively by Knit.
- [ProfileService](https://github.com/MadStudioRoblox/ProfileService) or [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) — DataStore session-locking for player data.
- [Zap](https://zap.redblox.dev/) — compiled, typed networking if Knit's built-in remotes aren't fast/strict enough later.
- [Fusion](https://elttob.uk/Fusion/) — declarative UI, if StarterGui scripting grows complex.

## Linting & Formatting

```bash
selene src
stylua src
```

Config lives in `selene.toml` and `stylua.toml`.
# Animate
