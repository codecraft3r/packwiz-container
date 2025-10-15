# packwiz-container
packwiz in a container

## Usage

There are two ways to specify your packwiz modpack:

### Method 1: Direct URL (Traditional)
Use a direct URL to your pack.toml file:

```bash
docker run -e PACKWIZ_URL=https://raw.githubusercontent.com/user/repo/main/pack.toml packwiz-container
```

### Method 2: GitHub Repository Variables (New)
Use GitHub repository information to automatically construct URLs and optionally fetch the latest release:

```bash
# Use latest release automatically
docker run \
  -e GH_USERNAME=yourusername \
  -e GH_REPO=yourrepo \
  packwiz-container

# Use specific version/tag
docker run \
  -e GH_USERNAME=yourusername \
  -e GH_REPO=yourrepo \
  -e PACK_VERSION="v1.2.3" \
  packwiz-container
```

## Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `PACKWIZ_URL` | * | Direct URL to pack.toml (takes priority) | `https://raw.githubusercontent.com/user/repo/main/pack.toml` |
| `GH_USERNAME` | ** | GitHub username or organization | `myusername` |
| `GH_REPO` | ** | GitHub repository name | `my-modpack` |
| `PACK_VERSION` | No | Specific version/tag (if not set, uses latest release) | `v1.2.3`, `main` |
| `WHITELIST_JSON` | No | JSON array of whitelisted players | `[{"uuid":"...","name":"Player1"}]` |
| `MB_RAM` | No | Memory allocation in MB (default: 4096) | `8192` |

\* Either `PACKWIZ_URL` OR both `GH_USERNAME` and `GH_REPO` must be set  
\** Required when not using `PACKWIZ_URL`

## Priority System

1. **`PACKWIZ_URL`** - If set, uses this directly (no GitHub API calls)
2. **GitHub Variables** - If `PACKWIZ_URL` is not set, constructs URL from `GH_USERNAME`, `GH_REPO`, and `PACK_VERSION`
3. **Latest Release** - If `PACK_VERSION` is empty, automatically fetches latest GitHub release

## Examples

### Using Latest Release
Automatically uses the newest tagged release:
```bash
docker run -e GH_USERNAME=codecraft3r -e GH_REPO=my-modpack packwiz-container
```

### Using Specific Version
```bash
docker run -e GH_USERNAME=codecraft3r -e GH_REPO=my-modpack -e PACK_VERSION="v2.1.0" packwiz-container
```

### Using Main Branch
```bash
docker run -e GH_USERNAME=codecraft3r -e GH_REPO=my-modpack -e PACK_VERSION="main" packwiz-container
```

### Direct URL Override
```bash
docker run -e PACKWIZ_URL=https://example.com/custom/pack.toml packwiz-container
```

### With Additional Options
```bash
docker run \
  -e GH_USERNAME=codecraft3r \
  -e GH_REPO=my-modpack \
  -e MB_RAM="8192" \
  -e WHITELIST_JSON='[{"uuid":"550e8400-e29b-41d4-a716-446655440000","name":"Player1"}]' \
  -p 25565:25565 \
  -v ./world:/mnt/server/world \
  packwiz-container
```

## How It Works

1. Container starts and resolves the packwiz URL based on environment variables
2. If using GitHub variables without `PACK_VERSION`, fetches latest release via GitHub API
3. Downloads and parses `pack.toml` to determine Minecraft and modloader versions
4. Installs the appropriate server software (Forge, NeoForge, Fabric, or Quilt)
5. Runs packwiz installer to download mods
6. Starts the Minecraft server

The URL resolution happens both during initial setup and at runtime, ensuring you always get the most current version when using latest release mode.
