1iserial --speed=9600 --unit=0 --word=8 --parity=no --stop=1\
1iterminal_input serial\
1iterminal_output serial\
s/^\([ \t]*linux .*\)$/\1 console=tty0 console=ttyS0,38400n8/
