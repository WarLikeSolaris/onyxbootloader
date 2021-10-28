# onyxbootloader
bootloader designed to read off ext2 volumes.

# things to know
bootloader looks for "/boot/loader", it will then read it from the disk
and then transfer execution to loader.

# examples and documentation i used

https://wiki.osdev.org/Ext2#What_is_an_Inode.
Great reference for everything ext2

https://github.com/lazear/ext2-boot
Example code I studied and enjoyed

http://www.osdever.net/tutorials/view/the-world-of-protected-mode
Very helpful with implementing protected mode stuff
