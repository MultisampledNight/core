{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "hq";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "MultisampledNight";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-RlWzqCKV56jV4mpPTSy7IHgPpXxJL4ODX5e1pLYI5bo=";
  };

  cargoHash = "sha256-FTfIffZDC7wWrvCJ5nMfMclFE7/uj3Mvuq+454MNkrM=";

  meta = with lib; {
    description = " Filter HTML on the command line. Fork of htmlq with some cleanup done.";
    homepage = "https://github.com/MultisampledNight/hq";
    license = licenses.mit;
    maintainers = with maintainers; [
      multisn8
    ];
    mainProgram = "hq";
  };
}
