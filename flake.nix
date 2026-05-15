{
  description = "iPod gadget kernel module – IDE dev environment (Linux 6.12, Raspberry Pi OS 13)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};

    kernel      = pkgs.linuxPackages_6_12.kernel;
    kernelBuild = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        clang-tools   # clangd for VS Code
        gnumake
        bear          # generates compile_commands.json via: bear -- make
      ];

      shellHook = ''
        KERNEL_BUILD="${kernelBuild}"

        mkdir -p .vscode

        # c_cpp_properties.json – tells IntelliSense where the kernel headers live
        cat > .vscode/c_cpp_properties.json << 'VSCODE_EOF'
{
  "configurations": [
    {
      "name": "Linux 6.12 – Raspberry Pi (ARM)",
      "includePath": [
        "''${workspaceFolder}/**",
        "KERNEL_BUILD_PLACEHOLDER/include",
        "KERNEL_BUILD_PLACEHOLDER/arch/arm/include",
        "KERNEL_BUILD_PLACEHOLDER/arch/arm/include/generated",
        "KERNEL_BUILD_PLACEHOLDER/arch/arm64/include",
        "KERNEL_BUILD_PLACEHOLDER/arch/arm64/include/generated"
      ],
      "defines": [
        "__KERNEL__",
        "MODULE",
        "KBUILD_MODNAME=\\\"g_ipod_gadget\\\""
      ],
      "compilerPath": "CLANGD_PLACEHOLDER",
      "cStandard": "gnu11",
      "intelliSenseMode": "linux-clang-arm",
      "browse": {
        "path": ["KERNEL_BUILD_PLACEHOLDER/include"]
      }
    }
  ],
  "version": 4
}
VSCODE_EOF

        # Replace placeholders with actual nix store paths
        sed -i "s|KERNEL_BUILD_PLACEHOLDER|$KERNEL_BUILD|g" .vscode/c_cpp_properties.json
        sed -i "s|CLANGD_PLACEHOLDER|$(which clang)|g"      .vscode/c_cpp_properties.json

        # settings.json – point VS Code clangd extension to the right binary
        cat > .vscode/settings.json << SETTINGS_EOF
{
  "clangd.path": "$(which clangd)",
  "C_Cpp.intelliSenseEngine": "disabled",
  "clangd.arguments": [
    "--background-index",
    "--clang-tidy=false"
  ]
}
SETTINGS_EOF

        echo ""
        echo "Kernel headers: $KERNEL_BUILD"
        echo ".vscode/c_cpp_properties.json written."
        echo ""
        echo "Tip: run  bear -- make -C gadget  once to generate compile_commands.json"
        echo "     clangd prefers that over c_cpp_properties.json."
        echo ""
      '';
    };
  };
}
