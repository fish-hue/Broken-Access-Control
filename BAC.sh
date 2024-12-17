#!/bin/bash

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Exiting."
    exit 1
fi

# Define the base URL
echo "Enter the base URL of the application (e.g., http://example.com):"
read BASE_URL

# Validate URL input
if [[ -z "$BASE_URL" || ! "$BASE_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
    echo "Valid base URL is required (e.g., http://example.com). Exiting."
    exit 1
fi

# Prompt for custom endpoints (optional)
echo "Would you like to enter custom endpoints to test? (y/n)"
read CUSTOM_ENDPOINTS
if [[ "$CUSTOM_ENDPOINTS" =~ ^[Yy]$ ]]; then
    echo "Enter your custom endpoints, separated by spaces (e.g., /admin /user/profile /settings):"
    read -a ENDPOINTS
else
    # Define default endpoints if custom input is not provided
    ENDPOINTS=(
      "/admin"
      "/user/profile"
      "/settings"
    )
fi

# Prompt for the authorization method
echo "Select the authorization method:"
echo "1) Bearer Token"
echo "2) Cookie"
echo "3) Basic Auth"
read -p "Enter your choice (1/2/3): " AUTH_METHOD

# Function to get authorization header
get_auth_header() {
  local method=$1
  case $method in
    1)
      read -p "Enter your Bearer token: " AUTH_TOKEN
      if [ -z "$AUTH_TOKEN" ]; then
        echo "Bearer token cannot be empty. Exiting."
        exit 1
      fi
      echo "Authorization: Bearer $AUTH_TOKEN"
      ;;
    2)
      read -p "Enter your cookie value: " COOKIE_VALUE
      if [ -z "$COOKIE_VALUE" ]; then
        echo "Cookie value cannot be empty. Exiting."
        exit 1
      fi
      echo "Cookie: $COOKIE_VALUE"
      ;;
    3)
      read -p "Enter your username: " USERNAME
      read -sp "Enter your password: " PASSWORD
      echo
      if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
        echo "Username and password cannot be empty. Exiting."
        exit 1
      fi
      echo "--user $USERNAME:$PASSWORD"
      ;;
    *)
      echo "Invalid authorization method selected. Exiting."
      exit 1
      ;;
  esac
}

# Initialize token/cookie/user credentials
AUTH_HEADER=$(get_auth_header $AUTH_METHOD)

# Prompt for custom headers (optional)
echo "Would you like to include custom headers? (y/n)"
read CUSTOM_HEADERS
if [[ "$CUSTOM_HEADERS" =~ ^[Yy]$ ]]; then
    echo "Please enter the custom headers in the format: key: value, separated by commas."
    echo "Example: X-API-Key: some_api_key, X-User-Agent: myagent"
    read -p "Custom Headers: " CUSTOM_HEADER_INPUT
    CUSTOM_HEADER=()
    while IFS=',' read -r header; do
        CUSTOM_HEADER+=(-H "$header")
    done <<< "$CUSTOM_HEADER_INPUT"
else
    CUSTOM_HEADER=()  # Initialize to empty array if no custom headers
fi

# Prompt for the HTTP method
echo "Please select the HTTP method you want to use for the requests."
echo "You can choose between: GET, POST, PUT, or DELETE."
echo "Available options are:"
echo "GET: Retrieve data"
echo "POST: Send data to the server"
echo "PUT: Update existing data"
echo "DELETE: Remove data"
read -p "Enter HTTP Method (default: GET): " HTTP_METHOD
HTTP_METHOD=${HTTP_METHOD:-GET}  # Default to GET if not provided

# Validate HTTP method
if [[ ! "$HTTP_METHOD" =~ ^(GET|POST|PUT|DELETE)$ ]]; then
    echo "Invalid HTTP method: $HTTP_METHOD. Please enter GET, POST, PUT, or DELETE."
    exit 1
fi

# Prompt for logging option
echo "Would you like to log the output to a file? (y/n)"
read LOG_OPTION
if [[ "$LOG_OPTION" =~ ^[Yy]$ ]]; then
    read -p "Enter log file name for responses (default: response_log.txt): " RESPONSE_LOG_FILE
    RESPONSE_LOG_FILE=${RESPONSE_LOG_FILE:-response_log.txt}
    
    # Check if the response log file exists
    if [[ -f "$RESPONSE_LOG_FILE" ]]; then
        read -p "The file '$RESPONSE_LOG_FILE' already exists. Do you want to append (a) or overwrite (o)? [a/o]: " LOG_ACTION
        if [[ "$LOG_ACTION" =~ ^[Oo]$ ]]; then
            > "$RESPONSE_LOG_FILE"  # Overwrite the file
            echo "Log file '$RESPONSE_LOG_FILE' has been overwritten."
        fi
    fi

    read -p "Enter log file name for errors (default: error_log.txt): " ERROR_LOG_FILE
    ERROR_LOG_FILE=${ERROR_LOG_FILE:-error_log.txt}
    
    # Check if the error log file exists
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        read -p "The file '$ERROR_LOG_FILE' already exists. Do you want to append (a) or overwrite (o)? [a/o]: " LOG_ACTION
        if [[ "$LOG_ACTION" =~ ^[Oo]$ ]]; then
            > "$ERROR_LOG_FILE"  # Overwrite the file
            echo "Log file '$ERROR_LOG_FILE' has been overwritten."
        fi
    fi
else
    RESPONSE_LOG_FILE="/dev/null"  # Discard output if no logging is desired
    ERROR_LOG_FILE="/dev/null"      # Discard error logs if no logging is desired
fi

# Function to check access for each role
check_access() {
  local endpoint=$1
  
  # Prompt for timeout duration with validation
  while true; do
    read -p "Enter timeout duration (seconds) [default: 10]: " TIMEOUT
    TIMEOUT=${TIMEOUT:-10}  # Default to 10 seconds if not provided
    
    # Check if TIMEOUT is a valid number
    if [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
      break
    else
      echo "Invalid input. Please enter a valid number for timeout."
    fi
  done

  # Build the curl command with custom headers and HTTP method
  response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT -X $HTTP_METHOD -H "$AUTH_HEADER" "${CUSTOM_HEADER[@]}" "$BASE_URL$endpoint")

  if [ $? -ne 0 ]; then
    echo "Error: Unable to reach $BASE_URL$endpoint. Please check the server or your network connection." | tee -a "$ERROR_LOG_FILE"
    return
  fi

  # Check the response and display appropriate messages
  case "$response" in
    200) 
      msg="SUCCESS: Access granted to $endpoint"
      echo "$msg" | tee -a "$RESPONSE_LOG_FILE"
      ;;
    403) 
      msg="FORBIDDEN: Access denied to $endpoint"
      echo "$msg" | tee -a "$RESPONSE_LOG_FILE"
      ;;
    404) 
      msg="NOT FOUND: $endpoint does not exist"
      echo "$msg" | tee -a "$RESPONSE_LOG_FILE"
      ;;
    500) 
      msg="ERROR: Internal server error at $endpoint"
      echo "$msg" | tee -a "$ERROR_LOG_FILE"
      ;;
    *) 
      msg="Unexpected response $response ($endpoint)"
      echo "$msg" | tee -a "$ERROR_LOG_FILE"
      ;;
  esac
}

# Loop through endpoints and test access
for endpoint in "${ENDPOINTS[@]}"; do
  check_access "$endpoint"
  echo # Add a newline for better readability between results
done
