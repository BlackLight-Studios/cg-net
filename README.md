# CG-NET and Networking
### a collection of scripts and simple/small OSes for [CC: Tweaked](https://modrinth.com/mod/cc-tweaked) (on Minecraft)

## About this collection:

This contains 2.5 (3) OSes: NexusOS, for the main server (and doubles as NodeOS, but I'll get to that later) and NovaOS for clients. This was all made on the idea of making it simple and have a functioning network.

[YAP PART] I came up with this idea on a random Friday while playing with friends on a Minecraft server. While talking to eachother an idea comes to mind: adding ComputerCraft to the server. So after days of never knowing what to do on CC: Tweaked I finally came up with the idea of making and email system, a functional network and in the meantime add a mod to the said server. (there were 2 consecutive ideas, 1st one was making the email system, 2nd one was adding the mod to the server so it wouldn't be a random thing I would do and forget about it / not continue it anymore). This was a nice thing I came up with and it was also fun to do in a week or so (I finally had something to do), the code isn't that great so... feel free to judge me.

## About the OSes:

### NexusOS
NexusOS is the main OS for the central router / server, it comes with the 4 scripts for the networking to take place, a simple repo (to which the clients can access thru the package manager, use one of the files as template, the layout is the same for everything) and a small recovery script that copies the kernel.lua file and saves it in case you mess it up while doing something (surely I didn't make it because I messed up, nono...). This one isn't as customisable, but everything pretty much works on it's own, the scripts are somewhat straight-forward so I think it'll be easy to make quick fixes (because I KNOW I messed up something, and I'm sorry about it, but uhh I hope nothing is broken)??

### NodeOS
NodeOS is based on NexusOS and is the OS for the Proxies (or relays... or repeaters, call them whatever you want). It has most of the stuff the Nexus has, except for the Repo and has different nnet.lua files (the main file for the networking). Everytime a Node is created it automatically attempts to connect to the nearest Nexus or Node and can be optionally be changed manually inside the /etc/config.json file if you prefer it to connect to another proxy. Every Node's purpose is just to relay packets and emails back to their parent and then the Nexus and viceversa, I created them with the first idea of every server having an ender modem, but later on made them also work as repeaters... so you could say this system is best to be used with wireless modems (afterall they're cheaper too! *technically*)

### NovaOS
NovaOS was the last OS I made and it's the base system for the clients. It's more graphically pleasing than the previous 2 OSes (as it's more intended for "daily" use) and comes with a similar kernel.lua file, a built-in networkmanager.lua api that *should* have everything you need, just in case you can add stuff based on your needs... - it comes with a Netman app (yes, it's networkmanager but with 'work' and 'ager' cut off), that is used to search for a modem attached to the PC and open rednet on that modem, and is also used to search for a nearby Node and give options of which one to connect to (if there are more accessible ones in the area covered by the modem's range). It also has a package manager! Used with 'pacg' and it's used to install packages from the main Nexus.

:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3:3

## How to Install:

### NexusOS
There are two ways of installing NexusOS and NodeOS, first one is to either use the pastebin command for each OS, or use the pastebin command to download both installers and carry them inside a disk so to be able to install either system on the go.

It's easy to install, first copy the pastebin of the version you need, paste it into the terminal, execute it and then execute the installed file, it should prompt you if you want to install it and after it's completed you can **remove the pastebin file** and then... that's it.

**NexusOS**
`pastebin get EyGRsuzb nexusosinstaller.lua`

**NodeOS**
`pastebin get XHeuL7ra nodeosinstaller.lua`

**Disk**
 `pastebin get qN6qdX9w nexusdisk.lua`
 

### NovaOS
NovaOS works the same way, there's the installer for the Desktop version, the Portable version and one for the disk.

**Desktop**
`pastebin get 73Rj4PMe nodeosinstaller.lua`

**Portable**
`pastebin get p4DDpb9F portableinstaller.lua`

**Disk**
 `pastebin get Ef1W0AbU novadisk.lua`
 

