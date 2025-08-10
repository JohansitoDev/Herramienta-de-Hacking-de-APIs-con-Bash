#!/bin/bash

# API-Breaker: Una herramienta básica de hacking de APIs con Bash
# Autor: JohansitoDev


API_URL="https://pokeapi.co/api/v2/"
WORDLISTS_DIR="wordlists"
USER_AGENT="API-Breaker/1.0"

function show_help() {
    echo "Uso: $0 -u <URL de la API> -e <lista_de_endpoints> -p <lista_de_parametros>"
    echo ""
    echo "Opciones:"
    echo "  -u  URL base de la API (https://pokeapi.co/api/v2/)"
    echo "  -e  Ruta al archivo de wordlist para endpoints"
    echo "  -p  Ruta al archivo de wordlist para parámetros"
    echo "  -h  Mostrar esta ayuda"
    exit 1
}

function check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo "Error: La herramienta 'curl' no está instalada. Por favor, instálala."
        exit 1
    fi
}

function make_request() {
    local method=$1
    local url=$2
    local data=$3
    local headers=(-H "User-Agent: $USER_AGENT")

    echo "[$method] Intentando: $url"
    if [[ ! -z "$data" ]]; then
        echo "  - Datos: $data"
        curl_response=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$url" -d "$data" "${headers[@]}")
    else
        curl_response=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$url" "${headers[@]}")
    fi
    
    if [[ "$curl_response" == "200" || "$curl_response" == "201" ]]; then
        echo "  [ÉXITO] Respuesta HTTP: $curl_response"
    elif [[ "$curl_response" == "404" ]]; then
        echo "  [404] No encontrado"
    else
        echo "  [INFO] Respuesta HTTP: $curl_response"
    fi
}

check_dependencies

while getopts "u:e:p:h" opt; do
    case "$opt" in
        u) API_URL="$OPTARG";;
        e) ENDPOINT_WORDLIST="$OPTARG";;
        p) PARAM_WORDLIST="$OPTARG";;
        h) show_help;;
        *) show_help;;
    esac
done

if [[ -z "$API_URL" || -z "$ENDPOINT_WORDLIST" || -z "$PARAM_WORDLIST" ]]; then
    show_help
fi

echo "Iniciando API-Breaker contra $API_URL"
echo "-------------------------------------"
echo "## Escaneando Endpoints (GET)..."
while read -r endpoint; do
    make_request "GET" "$API_URL/$endpoint"
done < "$ENDPOINT_WORDLIST"

echo ""
echo "-------------------------------------"
echo "## Escaneando Parámetros (GET)..."
while read -r param; do
    make_request "GET" "$API_URL?${param}=test"
done < "$PARAM_WORDLIST"

echo ""
echo "-------------------------------------"
echo "## Buscando Inyección de Comandos..."
INJECTION_PAYLOADS=(";ls -la" "';ls -la'" "'||ls -la'")
while read -r endpoint; do
    for payload in "${INJECTION_PAYLOADS[@]}"; do
        make_request "GET" "$API_URL/$endpoint?id=$payload"
    done
done < "$ENDPOINT_WORDLIST"

echo ""
echo "-------------------------------------"
echo "API-Breaker ha finalizado."
