# onyxbootloader
simple x86 bootloader designed to read off ext2 volumes.

#### Of note:
bootloader looks for "/boot/loader", it will then read it from the disk and then transfer execution to loader.

#### Examples and documentation I used:
https://wiki.osdev.org/Ext2#What_is_an_Inode.
Great reference for everything ext2

https://github.com/lazear/ext2-boot
Great code that influenced my code heavily 

http://www.osdever.net/tutorials/view/the-world-of-protected-mode
Very helpful with implementing protected mode stuff

#### To-Do:
* Write second stage

* ELF execution capabilities

#### Building:
Just run
```
$ make
```
Then install to a disk or disk-image
```
$ dd if=./srt0.o of=/your/device bs=1024 count=1 
```
Enjoy
