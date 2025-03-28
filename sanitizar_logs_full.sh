#!/bin/bash

# Verifica argumento
if [ $# -ne 1 ]; then
  echo "Uso: $0 archivo_log"
  exit 1
fi

ARCHIVO="$1"
ARCHIVO_SALIDA="sanitized_$ARCHIVO"

# Sanitiza paso a paso con sed
sed -E \
  -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/XXX.XXX.XXX.XXX/g' \                                         # IPs
  -e 's/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/usuario@demo.com/g' \                 # Correos
  -e 's_https?://[a-zA-Z0-9./?=_-]+_https://demo.com/recurso_g' \                               # URLs
  -e 's/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/demo.com/g' \                                               # Dominios
  -e 's/\b[a-fA-F0-9]{32,64}\b/HASH_REMOVIDO/g' \                                                # Hashes tipo MD5/SHA
  -e 's/\buser[a-zA-Z0-9._-]*\b/usuario_demo/g' \                                                # Usernames genéricos (ajustable)
  -e 's_/(home|var|etc|opt|tmp|usr|root)/[a-zA-Z0-9/_-]+_/ruta/sanitaria_g' \                    # Paths locales
  "$ARCHIVO" > "$ARCHIVO_SALIDA"

echo "Archivo sanitizado guardado como: $ARCHIVO_SALIDA"
