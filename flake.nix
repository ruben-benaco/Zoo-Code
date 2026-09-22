{
  description = "Zoo Code VS Code extension development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Node.js 22.x — nixpkgs ships 22.x in unstable; pin to the exact
        # minor/patch by overriding the source if the packaged version drifts.
        nodejs = pkgs.nodejs_22;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "zoo-code";

          packages = with pkgs; [
            # ── Runtime ──────────────────────────────────────────────────────
            nodejs # Node.js 22.x  (matches .nvmrc / .tool-versions)
            corepack
            # ships pnpm/yarn/npm shims; activates pnpm 10.8.1
            # via packageManager field in package.json

            pnpm

            # ── Build tooling ─────────────────────────────────────────────
            python3 # node-gyp dependency (native addons)
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
            # ── Ensure local node_modules/.bin is on PATH ─────────────────
            export PATH="$PWD/node_modules/.bin:$PATH"
          '';
        };
      }
    );
}
