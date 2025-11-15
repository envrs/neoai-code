#!/usr/bin/env bash

# Usage: set_team_models.sh [required] [optional]
#
#   Required:
#     --id-token <string>          ID token                        example: eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXV...
#     --model-id <string>          Model IDs, comma separated      example: 1,2,3
#
#         Name                       ID
#         -----------------------------
#         Claude 3.5 Sonnet          0
#         Claude 3.7 Sonnet          1
#         Claude 4 Sonnet            2
#         Claude 4.5 Haiku           3
#         Claude 4.5 Sonnet          4
#         DeepSeek                   5
#         Gemini 2.0 Flash           6
#         Gemini 2.5 Flash           7
#         Gemini 2.5 Pro             8
#         Gemma 3 27B                9
#         GPT-4.1                    10
#         GPT-4o                     11
#         GPT-5                      12
#         GPT-OSS                    13
#         Llama 3.1 405B             14
#         Llama 3.1 70B              15
#         Llama 3.3 70B              16
#         Mistral 7B                 17
#         Qwen                       18
#         Neoai Protected          19
#
#     --team-name <string>         Team name                       example: NeoAi Team (case sensitive)
#                                                                          Use "default" for the default team
#
#     --url <string>               Server URL                      example: https://localhost
#
#   Optional:
#     --reset                                                      reset team models

# Default values
ID_TOKEN=""
MODEL_IDS=""
TEAM_NAME=""
SERVER_URL=""
RESET_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --id-token)
      ID_TOKEN="$2"
      shift 2
      ;;
    --model-id)
      MODEL_IDS="$2"
      shift 2
      ;;
    --team-name)
      TEAM_NAME="$2"
      shift 2
      ;;
    --url)
      SERVER_URL="$2"
      shift 2
      ;;
    --reset)
      RESET_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ "$RESET_MODE" == false ]]; then
  if [[ -z "$ID_TOKEN" || -z "$MODEL_IDS" || -z "$TEAM_NAME" || -z "$SERVER_URL" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --id-token <token> --model-id <ids> --team-name <name> --url <url> [--reset]"
    exit 1
  fi
else
  if [[ -z "$ID_TOKEN" || -z "$TEAM_NAME" || -z "$SERVER_URL" ]]; then
    echo "Error: Missing required arguments for reset mode"
    echo "Usage: $0 --id-token <token> --team-name <name> --url <url> --reset"
    exit 1
  fi
fi

# Construct base URL
BASE_URL="${SERVER_URL}/models"

# Silent curl request
# -s = silent
# -S = show errors
# --fail = fail if http return code is >= 400
set_team_models() {
  local url="${BASE_URL}/set_team_models"
  local data="{\"id_token\": \"$ID_TOKEN\", \"model_ids\": [$MODEL_IDS], \"team_name\": \"$TEAM_NAME\"}"
  curl -sS --fail \
    -H "Content-Type: application/json" \
    -d "$data" \
    "$url"
}

reset_team_models() {
  local url="${BASE_URL}/reset_team_models"
  local data="{\"id_token\": \"$ID_TOKEN\", \"team_name\": \"$TEAM_NAME\"}"
  curl -sS --fail \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$data" \
    "$url"
}

list_team_models() {
  local url="${BASE_URL}/list_team_models"
  local data="{\"id_token\": \"$ID_TOKEN\", \"team_name\": \"$TEAM_NAME\"}"
  curl -sS --fail \
    -H "Content-Type: application/json" \
    -d "$data" \
    "$url"
}

# Execute based on mode
if [[ "$RESET_MODE" == true ]]; then
  echo "Resetting team models..."
  reset_team_models
else
  echo "Setting team models..."
  set_team_models
fi

echo "Listing current team models..."
list_team_models
