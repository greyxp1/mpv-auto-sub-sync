{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  zlib,
}: let
  sources = {
    x86_64-linux = {
      url = "https://github.com/smacke/ffsubsync/releases/download/0.5.1/linux-x86_64.tar.gz";
      hash = "sha256-uopvuV4fnGPIIdwwY2hNT7tlXGY2qLwrCtxAgmmCFJA=";
    };
    aarch64-linux = {
      url = "https://github.com/smacke/ffsubsync/releases/download/0.5.1/linux-arm64.tar.gz";
      hash = "sha256-irBjei7a/Q9jHQC6NhAmBuneuwSpAtj7PpqEFtRiPiA=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
  stdenv.mkDerivation {
    pname = "ffsubsync-bin";
    version = "0.5.1";

    src = fetchurl source;
    dontUnpack = true;
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [zlib];

    installPhase = ''
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
    '';

    meta = {
      description = "Standalone ffsubsync binary";
      homepage = "https://github.com/smacke/ffsubsync";
      license = [lib.licenses.mit lib.licenses.gpl3Only];
      mainProgram = "ffsubsync";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
