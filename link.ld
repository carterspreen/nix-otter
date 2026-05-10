ENTRY(main)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

__sp = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .text : ALIGN(4)
    {
        *(.text)
        *(.text.*)
    } > RAM

    .data : ALIGN(4)
    {
        *(.data)
        *(.data.*)
    } > RAM

    . = ALIGN(4);
    _end = .;

    ASSERT(_end <= ORIGIN(RAM) + LENGTH(RAM), "program does not fit in RAM")
}
