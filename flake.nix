{
  description = "Zoo Code VS Code extension development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Node.js 22.x — nixpkgs ships 22.x in unstable; pin to the exact
        # minor/patch by overriding the source if the packaged version drifts.
        nodejs = pkgs.nodejs_22;

        # pnpm is provided as a standalone binary; corepack is the canonical
        # way to get an exact version, but nixpkgs also ships pnpm directly.
        # We use corepack so the version matches .tool-versions (10.8.1) exactly.
        pnpm = pkgs.nodePackages.pnpm or pkgs.pnpm;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "zoo-code";

          packages = with pkgs; [
            # ── Runtime ──────────────────────────────────────────────────────
            nodejs          # Node.js 22.x  (matches .nvmrc / .tool-versions)
            corepack        # ships pnpm/yarn/npm shims; activates pnpm 10.8.1
                            # via packageManager field in package.json

            # ── Build tooling ─────────────────────────────────────────────
            python3         # node-gyp dependency (native addons)
            gnumake
            gcc

            # ── VS Code extension packaging ───────────────────────────────
            # vsce is installed locally by pnpm; no global install needed.
            # Kept here as a convenience if you want to run it directly.
            # nodePackages."@vscode/vsce"  # uncomment if desired

            # ── General dev utilities ─────────────────────────────────────
            git
            jq
            curl
          ];

          shellHook = ''
            # ── Activate the exact pnpm version declared in package.json ──
            export COREPACK_ENABLE_STRICT=0
            corepack enable pnpm 2>/dev/null || true
            corepack prepare pnpm@10.8.1 --activate 2>/dev/null || true

            # ── Ensure local node_modules/.bin is on PATH ─────────────────
            export PATH="$PWD/node_modules/.bin:$PATH"

            echo ""
            echo "╔══════════════════════════════════════════════════════╗"
            echo "║          Zoo Code development environment            ║"
            echo "╠══════════════════════════════════════════════════════╣"
            printf "║  node  %-45s║\n" "$(node --version)"
            printf "║  pnpm  %-45s║\n" "$(pnpm --version 2>/dev/null || echo 'run: corepack prepare pnpm@10.8.1 --activate')"
            echo "╠══════════════════════════════════════════════════════╣"
            echo "║  Quick start:                                        ║"
            echo "║    pnpm install          # install all deps          ║"
            echo "║    pnpm vsix             # build .vsix package       ║"
            echo "║    pnpm install:vsix -y  # build + install into code ║"
            echo "╚══════════════════════════════════════════════════════╝"
            echo ""
          '';
        };
      });
}
