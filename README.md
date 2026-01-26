# NixOS Quantum
NixOS Quantum is an alternative way to out-of-store manage some of your dots. It's an alternative to using stow with symlinking. It uses bind-mounts so applications that write config files will not "unlink" the files linked, in addition you can bind-mount entire directories allowing you to capture newly created files into your quantum directory. 

### Q:

* Why not ...
  * home manager/hjem in-store solutions?  
    A: For some things I prefer to do out of store for instant feedback, or I am simply lazy.
  * use hjem-impure?  
    A: [hjem-impure](https://github.com/Rexcrazy804/hjem-impure) is an excellent way to manage dotfiles while still running in pure eval mode. I believe for most users this should be used over quantum. For the majority of cases you get the best of both worlds.
    Quantum is not a replacement to hjem-impure and I intend on using both in my own config. Quantum does not integrate with, or require hjem or home-manager, it is best seen as a niche tool for very specific purposes where symlinks are not sufficient.


    
### Installation: 
Add this to your flake's inputs: 
```nix
quantum = {
 url = "github:argosnothing/nixos-quantum";
};
```

Wherever you import stuff from your inputs simply do: 
```nix
modules = [
  inputs.quantum.nixosModules.default
];
```
You will need to setup the root quantum directory where quantum will store the entangled folders/files.
In my case I have this directory in my nixos-config under .quantum, as I use this as a stow alternative. 
```nix
quantum = {
  quantum-dir = "/home/${username}/nixos-config/.quantum";
    inherit username;
};
```

Example use: 
This will bind mount ~/home/${username}/nixos-config/.quantum/.config/xfce to ~/.config/xfce ( this is why you need to supply the username ). 
```nix
quantum.directories = [
  ".config/xfce4"
];
```
You can also bindmount files in a similar way with `quantum.files`

### Entanglement
You do not need to map the directories in your quantum directory to the structure of your home dir you want it mapped to. 
```nix
quantum.entangle-files = {
  "wowza" = "banana/wowza";
};
```
When powerful use of this is to maintain separate out of store gtk configs for different desktop environments. You could have a plasma quantum entangle with its own gtk folders, and a gnome one with its own, by using diff parent directories that map onto the homes gtk. 

example: 
gnome
```nix
quantum.entangle-folders = {
  "gnome/.config/gtk-3.0" = ".config/gtk-3.0";
};
```
plasma
```nix
quantum.entangle-folders = {
  "plasma/.config/gtk-3.0" = ".config/gtk-3.0";
};
```
As you can see both of these entangles have the same destination, so you should not try and have both of these configs enabled at the same time as this will cause a collision/undefined behavior. However this can be very powerfull if you want to fully separate different environments without needing to worry about nix store stuff. 
