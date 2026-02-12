{
  runtimeShell,
  makeWrapper,
  stdenv,
  lib,
  gum,
  ffmpeg,
  imagemagick,
  coreutils,
  file,
}:
stdenv.mkDerivation rec {
  name = "memify";
  version = "0-unstable-2026-2-12";

  src = ./memify.sh;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    gum
    ffmpeg
    imagemagick
    coreutils
    file
  ];

  installPhase = ''
    cat <(echo "#!${runtimeShell}") <(sed '1,/^# --- Start ---/d' $src) |
        install -Dm755 /dev/stdin $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : '${lib.makeBinPath buildInputs}'
  '';

  meta = {
    description = "CLI meme generator";
    homepage = "https://github.com/Nadim147c/memify";
    license = lib.licenses.gpl3Only;
    mainProgram = name;
  };
}
