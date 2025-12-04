# Básico (envía todo el archivo por UDP)
./my_logrun_plus.pl -f mis_logs.txt

# Solo 50 eventos
./my_logrun_plus.pl -f mis_logs.txt 50

# TCP + spoof IP origen + delay de 0.5s
./my_logrun_plus.pl -f mis_logs.txt -t -u 10.10.10.55 -d 0.5 100

# Bucle infinito (perfecto para pruebas continuas)
./my_logrun_plus.pl -f apache_logs.txt -l -d 0.1 -t -h 192.168.100.10

# Con facility/severity personalizados
./my_logrun_plus.pl -f windows_logs.txt --facility auth --severity warning 200