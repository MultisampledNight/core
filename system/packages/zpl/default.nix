{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "zpl";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "felixhenninger";
    repo = pname;
    rev = "0d50c87b91f14f48125fd5206d81c752b8fac416";
    hash = "sha256-oumEQbrmeOYqaziPJXhHUTshYmZ49YGxfYT8Bx2cvvY=";
  };

  cargoHash = "sha256-zUW2HjQi4gebu5asOApprwsxCVhcHjsDLC/FVyPkz14=";

  meta = with lib; {
    description = "sticker printer";
    homepage = "https://github.com/felixhenniger/zpl";
    maintainers = [ maintainers.multisn8 ];
  };
}
