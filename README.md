# mpv-auto-sub-sync

Automatically synchronizes the active subtitle track to the selected audio track when mpv opens a local file. Synchronization runs in the background using [ffsubsync](https://github.com/smacke/ffsubsync) so no key press or menu is required.

It supports external and embedded SRT, ASS, and SSA subtitles. The original subtitle remains unchanged, and temporary files are removed when playback ends.

## Nix

Add the flake:

```nix
inputs.mpv-auto-sub-sync.url = "github:greyxp1/mpv-auto-sub-sync";
```

With Home Manager, include the package in mpv's scripts:

```nix
programs.mpv = {
  enable = true;
  scripts = [
    inputs.mpv-auto-sub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  config.watch-later-options-remove = "sid";
};
```

The Nix package supports x86-64 and ARM64 Linux and includes the compact official ffsubsync binary and FFmpeg runtime integration.

Without Home Manager, pass the script package when wrapping mpv:

```nix
pkgs.mpv.override {
  scripts = [
    inputs.mpv-auto-sub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Other Linux distributions

Install `ffmpeg` and `ffsubsync`, then copy `auto-sub-sync.lua` into `~/.config/mpv/scripts/`.
