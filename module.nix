{
  config,
  lib,
  pkgs,
  ...
}: let
  prune-script = pkgs.writeShellScriptBin "quantum-prune" (builtins.readFile ./scripts/quantum-prune.sh);
  assertNoHomeDirs = paths:
    assert (lib.assertMsg (!lib.any (lib.hasPrefix "/home") paths) "/home used in a root link!"); paths;
  user = config.quantum.username;
  home = "/home/${user}";
  quantum-root = config.quantum.quantum-dir;
  dirs = config.quantum.directories or [];
  files = config.quantum.files or [];
  entangle-folders = config.quantum.entangle-folders or {};
  entangle-files = config.quantum.entangle-files or {};

  mkMount = rel: {
    what = "${quantum-root}/${rel}";
    where = "${home}/${rel}";
    type = "none";
    options = "bind,nofail";
    wantedBy = ["local-fs.target"];

    # Prune first!
    after = ["quantum-prune.service"];
    requires = ["quantum-prune.service"];
  };

  mkEntangleMount = src: dst: {
    what = "${quantum-root}/${src}";
    where = "${home}/${dst}";
    type = "none";
    options = "bind,nofail";
    wantedBy = ["local-fs.target"];

    # Prune first!
    after = ["quantum-prune.service"];
    requires = ["quantum-prune.service"];
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

  entangle-file-dsts = builtins.attrValues entangle-files;
  entangle-folder-dsts = builtins.attrValues entangle-folders;
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
      entangle-files = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          path relative to quantum directory → path relative to home.
        '';
      };
      entangle-folders = lib.mkOption {
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
      ++ (builtins.filter (x: x != null) (map mkParentRule entangle-file-dsts))
      ++ (map mkFileRule entangle-file-dsts)
      ++ (map mkDirRule entangle-folder-dsts);

    systemd.mounts =
      (map mkMount dirs)
      ++ (map mkMount files)
      ++ (lib.mapAttrsToList mkEntangleMount entangle-files)
      ++ (lib.mapAttrsToList mkEntangleMount entangle-folders);

    systemd.services.quantum-prune = {
      description = "Quantum: prune conflicting mountpoints before bind mounts";
      serviceConfig = {
        Type = "oneshot";
        Environment = [
          "FINDMNT_BIN=${pkgs.util-linux}/bin/findmnt"
          "UMOUNT_BIN=${pkgs.util-linux}/bin/umount"
          "RM_BIN=${pkgs.coreutils}/bin/rm"
        ];
        ExecStart = lib.concatStringsSep " " ([
            "${prune-script}/bin/quantum-prune"
            "--home"
            home
          ]
          ++ lib.concatMap (p: ["--files" p]) (files ++ entangle-file-dsts)
          ++ lib.concatMap (p: ["--dirs" p]) (dirs ++ entangle-folder-dsts));
      };
    };
  };
}
