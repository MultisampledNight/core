{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    envision
    openxr-loader
    openxr-loader.dev

    monado-vulkan-layers
    vulkan-headers
    vulkan-loader
    vulkan-tools
    vulkan-tools-lunarg
    vulkan-validation-layers
    vulkan-extension-layer
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<vr>"
  '';
}
