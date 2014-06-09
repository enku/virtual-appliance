1iserial --speed=9600 --unit=0 --word=8 --parity=no --stop=1\
1iterminal --timeout=2 serial console\
s/^\(kernel .*\)$/\1 console=ttyS0/
