{
  callPackage,
  ffmpeg-headless,
  lib,
  mpvScripts,
  symlinkJoin,
  writeCBin,
}: let
  ffsubsync = callPackage ./ffsubsync-bin.nix {};
  launcher = name:
    writeCBin name ''
      #include <stdlib.h>
      #include <unistd.h>

      int main(int argc, char **argv) {
        (void) argc;
        unsetenv("LD_LIBRARY_PATH");
        execv("${lib.getExe' ffmpeg-headless name}", argv);
        return 127;
      }
    '';
  runtime = symlinkJoin {
    name = "mpv-auto-sub-sync-runtime";
    paths = [
      ffsubsync
      (launcher "ffmpeg")
      (launcher "ffprobe")
    ];
  };
in
  mpvScripts.buildLua {
    pname = "mpv-auto-sub-sync";
    version = "0-unstable-2026-08-29";
    src = lib.cleanSource ./.;
    scriptPath = "auto-sub-sync.lua";
    runtime-dependencies = [runtime];

    passthru = {inherit ffsubsync runtime;};

    meta = {
      description = "Automatically synchronize mpv subtitles with ffsubsync";
      homepage = "https://github.com/greyxp1/mpv-auto-sub-sync";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
