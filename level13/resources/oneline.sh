gdb -q ./level13 -ex "break *0x0804859a" -ex "run" -ex "set \$eax=4242" -ex "continue" -ex "quit"
