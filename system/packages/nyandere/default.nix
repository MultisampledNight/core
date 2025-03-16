{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "nyandere";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "5706e3a19737c13a1dfa5043bbd4d965b2457932";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  meta = with lib; {
    description = "Scripting language for personal purchase tracking and analysis.";
    homepage = "https://github.com/MultisampledNight/nyandere";
    maintainers = [ maintainers.multisn8 ];
  };
}
