# NixOS Quantum
NixOS Quantum is an alternative way to out-of-store manage some of your dots. It's an alternative to using stow with symlinking. It uses bind-mounts so applications that write config files will not "unlink" the files linked, in addition you can bind-mount entire directories allowing you to capture newly created files into your quantum directory. 

Q:

* Why not ...
  * home manager/hjem in-store solutions?  
    A: For some things I prefer to do out of store for instant feedback, or I am simply lazy.
  * use hjem-impure?  
    A: [hjem-impure](https://github.com/Rexcrazy804/hjem-impure) is an excellent way to manage dotfiles while still running in pure eval mode. I believe for most users this should be used over quantum. For the majority of cases you get the best of both worlds.
    Quantum is not a replacement to hjem-impure and I intend on using both in my own config. Quantum does not integrate with, or require hjem or home-manager, it is best seen as a niche tool for very specific purposes where symlinks are not sufficient.


    
