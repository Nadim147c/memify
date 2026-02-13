{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  ffmpeg,
  file,
  gnused,
  google-fonts,
  gum,
  imagemagick,
}:
let
  font = google-fonts.override { fonts = [ "Anton" ]; };
  fontfile = "${font}/share/fonts/truetype/Anton-Regular.ttf";
  src = runCommand "memify-src" { } ''
    sed '1,/^# --- Start ---/d' ${./memify.sh} > $out
    sed -i 's#-font Anton-Regular#-font ${fontfile}#' $out
  '';
in
writeShellApplication rec {
  name = "memify";
  inheritPath = false;
  runtimeInputs = [
    coreutils
    ffmpeg
    file
    gnused
    gum
    imagemagick
  ];
  text = builtins.readFile "${src}";
  meta = {
    description = "CLI meme generator";
    homepage = "https://github.com/Nadim147c/memify";
    license = lib.licenses.gpl3Only;
    mainProgram = name;
  };
}
