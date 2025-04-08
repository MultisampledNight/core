{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "layaway";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-SzAuVFEy56svasO3+1p6ysBRrIQd0UZX++/P4ZuwWm0=";
  };

  cargoHash = "sha256-QVxlkE+sq4U048LnshI/tq6HInKiSgjQLAdR+27/wEI=";

  meta = with lib; {
    description = "Layout creation for Sway via a relative and human-readable DSL.";
    homepage = "https://github.com/MultisampledNight/layaway";
    maintainers = [ maintainers.multisn8 ];
  };
}
