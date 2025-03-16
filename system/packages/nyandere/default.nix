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
    hash = "sha256-vzQXPlR78/m9mB8pflsa7WCIMSuoWdczRcgo6yj3gcM=";
  };

  cargoHash = "sha256-L2LOjKdU/6bkzw0ZrebARhR/MmwC0ET3rVZzhf1VQho=";

  meta = with lib; {
    description = "Scripting language for personal purchase tracking and analysis.";
    homepage = "https://github.com/MultisampledNight/nyandere";
    maintainers = [ maintainers.multisn8 ];
  };
}
