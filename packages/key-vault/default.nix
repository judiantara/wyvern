{ stdenv, lib }:

let
  fs = lib.fileset;
  sourceFiles = (fs.fileFilter (file: file.hasExt "age") ./keys);
in

stdenv.mkDerivation rec {
  name = "key-vault";
  version = "latest";

  src = fs.toSource {
    root = ./keys;
    fileset = sourceFiles;
  };

  unpackPhase  = ":";
  buildPhase   = ":";
  installPhase = ''
    mkdir -p $out
    install -m444 ${src}/*.age $out
  '';
}
