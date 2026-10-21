#!/bin/bash

# 1. Defina a lista de pastas que você quer varrer
pastas=(
    "lib/features/gestor/"
    "lib/features/colaborador"
    )

# Limpa/cria o arquivo final
> codigo_lib.txt

# 2. Percorre cada pasta e busca todos os arquivos dentro delas
for pasta in "${pastas[@]}"; do
    if [ -d "$pasta" ]; then
        find "$pasta" -type f | while read -r arquivo; do
            echo "=== ARQUIVO: $arquivo ===" >> codigo_lib.txt
            cat "$arquivo" >> codigo_lib.txt
        done
    else
        echo "Aviso: A pasta '$pasta' não existe."
    fi
done
