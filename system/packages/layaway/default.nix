{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "layaway";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-dc5wxDueXM5XthrKNVpjVCwq8gieEXMzG/bI9en7UbE=";
  };

  cargoHash = "sha256-fXEASSZTlQaA0efh9rotOAB7zVWIZLLQm4denn50Qcc=";

  meta = with lib; {
    description = "Layout creation for Sway via a relative and concise DSL.";
    homepage = "https://github.com/MultisampledNight/layaway";
    maintainers = with maintainers; [ multisn8 ];
  };
}
