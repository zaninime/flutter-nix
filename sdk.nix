{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib stdenv fetchurl;
  platform = "linux";

  baseSdk = stdenv.mkDerivation rec {
    pname = "flutter-sdk";
    # version = "1.7.8.4";
    version = "1.7.8+hotfix.4-stable";

    src = fetchurl {
      url = "https://storage.googleapis.com/flutter_infra/releases/stable/${platform}/flutter_${platform}_v${version}.tar.xz";
      sha256 = "1mwbacwz0gh4ijdv0c2207v4yq7fifyq6zwmwb9x4r3y0g411l67";
    };

    installPhase = ''
      mkdir -p $out
      cp -r ./. $out
    '';

    postFixup = ''
      find $out/bin/cache/dart-sdk/bin -type f -executable -exec patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" {} \;
    '';
  };
in

stdenv.mkDerivation rec {
  pname = "flutter-sdk-warm";
  version = baseSdk.version;

  outputHash = "006cr12bgnb7r83r4gmxankz1iismz7zz8anff6vkcymm6jfvpbz";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";

  src = baseSdk;

  buildInputs = with pkgs; [ git ];

  buildPhase = ''
    export HOME="$(pwd)/home"
    mkdir "$HOME"
    bin/flutter precache

    rm -rf .pub-cache
  '';

  installPhase = ''
    mkdir -p $out

    cp -r ./. $out
  '';

  postFixup = ''
    find $out/bin/cache/artifacts -type f -executable -exec patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" {} \;

    i686_interpreter="$(echo ${pkgs.pkgsi686Linux.stdenv.glibc.out}/lib/ld-linux*)"
    find $out/bin/cache/artifacts/engine -name gen_snapshot -exec patchelf --set-interpreter "$i686_interpreter" --set-rpath "${lib.makeLibraryPath [ pkgs.pkgsi686Linux.stdenv.cc.cc ]}" {} \;
  '';
}
