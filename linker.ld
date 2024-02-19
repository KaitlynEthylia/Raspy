ENTRY(_start)

SECTIONS {
	.text : {
		*(.text.boot)
		*(.text*)
	}

	.rodata : { *(.rodata*) }
	.data : { *(.data*) }

	.bss ALIGN(0x08) : {
		bss_start = .;
		*(.bss*)
		bss_end = .;
	}
}
