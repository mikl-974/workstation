{ pkgs }:
let
  vibe-notion = pkgs.callPackage (
    {
      lib,
      buildNpmPackage,
      fetchurl,
      makeWrapper,
      nodejs,
      python3,
      pkg-config,
    }:
    buildNpmPackage rec {
      pname = "vibe-notion";
      version = "1.8.1";

      src = fetchurl {
        url = "https://registry.npmjs.org/vibe-notion/-/vibe-notion-${version}.tgz";
        hash = "sha512-nE2jRQadpx9NgEo6AoJ5qMvHOMv56oNmQx2yRaODad5/vKCZi4qkeXRZjnYICm+6NiyyU2oAJALOLZq3abYk8g==";
      };

      sourceRoot = "package";
      npmDepsHash = "sha256-4iR6TLbAhIEMh1EwMouVmbfA0Rj910R75GLCTzp+R40=";

      postPatch = ''
        cp ${./vibe-notion-package-lock.json} package-lock.json
      '';

      nativeBuildInputs = [
        makeWrapper
        pkg-config
        python3
      ];

      dontNpmBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/lib/${pname}" "$out/bin"
        cp -r . "$out/lib/${pname}"

        makeWrapper ${nodejs}/bin/node "$out/bin/vibe-notion" \
          --add-flags "$out/lib/${pname}/dist/src/platforms/notion/cli.js"

        makeWrapper ${nodejs}/bin/node "$out/bin/vibe-notionbot" \
          --add-flags "$out/lib/${pname}/dist/src/platforms/notionbot/cli.js"

        runHook postInstall
      '';

      meta = {
        description = "Notion API CLI for AI agents";
        homepage = "https://github.com/devxoul/vibe-notion";
        license = lib.licenses.mit;
        mainProgram = "vibe-notion";
        platforms = lib.platforms.linux;
      }; 
    }
  ) { };
in
[
  vibe-notion
]