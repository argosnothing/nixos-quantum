{
  description = "Quantum: A bind mounting solution for NixOS";

  outputs = { ... }: {
    nixosModules.quantum = import ./module.nix;
    nixosModules.default = import ./module.nix;
  };
}
