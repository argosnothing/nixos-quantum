{
  config,
  lib,
  ...
}: let
  assertNoHomeDirs = paths:
    assert (lib.assertMsg (!lib.any (lib.hasPrefix "/home") paths) "/home used in a root link!"); paths;
  user = config.quantum.username;
  home = "/home/${user}";
  quantum-root = config.quantum.quantum-dir;
  dirs = config.quantum.directories or [];
  files = config.quantum.files or [];
  entangle = config.quantum.entangle or {};

  mkMount = rel: {
    what = "${quantum-root}/${rel}";
    where = "${home}/${rel}";
    type = "none";
    options = "bind,nofail";
    wantedBy = ["local-fs.target"];
  };

  mkEntangleMount = src: dst: {
    what = "${quantum-root}/${src}";
    where = "${home}/${dst}";
    type = "none";
    options = "bind,nofail";
    wantedBy = ["local-fs.target"];
  };

  mkDirRule = rel: "d ${home}/${rel} 0755 ${user} users - -";
  mkFileRule = rel: "f ${home}/${rel} 0644 ${user} users - -";

  parentDir = p: let
    m = builtins.match "(.+)/[^/]+$" p;
  in
    if m == null
    then "."
    else builtins.elemAt m 0;

  mkParentRule = rel: let
    pd = parentDir rel;
  in
    if pd == "."
    then null
    else "d ${home}/${pd} 0755 ${user} users - -";

  entangleDsts = builtins.attrValues entangle;
in {
  options = {
    quantum = {
      quantum-dir = lib.mkOption {
        type = lib.types.str;
        description = "Directory root of quantum";
      };
      username = lib.mkOption {
        type = lib.types.str;
        description = "User of quantum";
      };
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        apply = assertNoHomeDirs;
        description = "Directories to entangle in quantum directory";
      };
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        apply = assertNoHomeDirs;
        description = "Files to entangle in quantum directory";
      };
      entangle = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          path relative to quantum directory → path relative to home.
        '';
      };
    };
  };
  config = {
    systemd.tmpfiles.rules =
      (builtins.filter (x: x != null) (map mkParentRule files))
      ++ (map mkDirRule dirs)
      ++ (map mkFileRule files)
      ++ (builtins.filter (x: x != null) (map mkParentRule entangleDsts))
      ++ (map mkFileRule entangleDsts);

    systemd.mounts =
      (map mkMount dirs)
      ++ (map mkMount files)
      ++ (lib.mapAttrsToList mkEntangleMount entangle);
  };
}
