{ pkgs, lib, ... }:
let
  dprintConfig =
    with lib;
    pipe ./dprint.json [
      readFile
      strings.fromJSON
      (filterAttrs (
        n: v:
        !(elem n [
          "plugins"
          "excludes"
          "includes"
        ])
      ))
    ];
in
{
  projectRootFile = "flake.nix";
  programs = {
    dprint = {
      enable = true;
      includes = [
        "**/*.toml"
        "**/*.json"
        "**/*.yaml"
        "**/*.yml"
        "**/*.md"
      ];
      settings = dprintConfig // {
        plugins = pkgs.dprint-plugins.getPluginList (
          p: with p; [
            dprint-plugin-toml
            dprint-plugin-markdown
            g-plane-pretty_yaml
            dprint-plugin-json
          ]
        );
      };
    };
    just = {
      enable = true;
      includes = [ ".justfile" ];
    };
    nixfmt = {
      enable = true;
    };
    shellcheck = {
      enable = true;
      includes = [
        "scripts/*"
        "*.envrc"
        "*.envrc.*"
      ];
    };
    shfmt = {
      enable = true;
      includes = [
        "scripts/*"
        "*.envrc"
        "*.envrc.*"
      ];
    };
    typos = {
      enable = true;
      includes = [ "**/*" ];
      excludes = [ "*.mp3" ];
      configFile = toString ./typos.toml;
    };
  };
}
