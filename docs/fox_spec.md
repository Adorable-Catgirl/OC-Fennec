# FOX Spec executable Package
FOX Spec packages have two to four sections: The code section, the manifest section, the linker section, and the archive section.

## Header format
```c
struct FOX_Spec_Header {
	char magic[8]; // Should be `fox_spec` or `ceps_xof`, depending on endianess.
	unsigned short code;
	unsigned short manifest;
	unsigned short linker;
	unsigned short archive;
};
```

## Linker section
The linker section starts with an unsigned short, stating how many entries there are. Each entry is prefixed by an unsigned char that states the length of the entry in the linker table. After this, it states how many arguments it takes, and what types.
Example: `<0x01><0x00><0x10>init.hello_world<0x01>s`

## Archive section
The archive may be any of the supported formats. It's mounted in the proc vfs at `$/`. Executable code for a library may be placed in the `$/lib/` directory.

## As an archive.
The code section should be displayed as `init.lua`, the manifest as `manifest.mf`, the linker section as `link.dat`, and the archive as an underlying filesystem.

## File extensions
FOX spec executables should have the extension `fox` and the libraries have the extension `vul`