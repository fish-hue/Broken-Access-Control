# BAC.sh a Broken Access Control tool

## Overview

**BAC.sh** is a Bash script designed to facilitate testing of access to various endpoints from a specified base URL. It supports multiple HTTP methods (GET, POST, PUT, DELETE), provides options for authorization (Bearer Token, Cookie, Basic Auth), and allows for the inclusion of custom headers. The script can log the responses and errors to specified output files.

## Features

- Select from various HTTP methods (GET, POST, PUT, DELETE).
- Choose from multiple authorization methods (Bearer Token, Cookie, Basic Auth).
- Include custom headers with instructions for formatting.
- Log responses and errors to files, with options to append to or overwrite existing logs.
- Set a timeout for requests.

## Requirements

- A Unix-like environment (Linux, macOS).
- `curl` must be installed.

## Installation

1. Clone or download this repository.
2. Ensure the script has execution permissions. You can set it with:
   ```bash
   chmod +x BAC.sh
   ```

## Usage

1. Open a terminal and navigate to the directory containing the script.
2. Run the script with:
   ```bash
   ./BAC.sh
   ```

3. Follow the prompts to:
   - Enter the base URL.
   - Optionally enter custom endpoints.
   - Select an authorization method and provide the necessary credentials.
   - Optionally add custom headers in the format `key: value` separated by commas.
   - Choose the desired HTTP method.
   - Specify logging preferences for responses and errors.

## Example

```bash
$ ./http_access_tester.sh
Enter the base URL of the application (e.g., http://example.com):
Base URL: http://api.example.com
Would you like to enter custom endpoints to test? (y/n): y
Enter your custom endpoints, separated by spaces (e.g., /admin /user/profile /settings):
/users /products
Select the authorization method:
1) Bearer Token
2) Cookie
3) Basic Auth
Enter your choice (1/2/3): 1
Enter your Bearer token: your_token_here
Would you like to include custom headers? (y/n): y
Please enter the custom headers in the format: key: value, separated by commas.
Example: X-API-Key: some_api_key, X-User-Agent: myagent
Custom Headers: X-API-Key: my_api_key, X-User-Agent: myagent
Please select the HTTP method you want to use for the requests.
You can choose between: GET, POST, PUT, or DELETE.
Available options are:
GET: Retrieve data
POST: Send data to the server
PUT: Update existing data
DELETE: Remove data
Enter HTTP Method (default: GET): GET
Would you like to log the output to a file? (y/n): y
Enter log file name for responses (default: response_log.txt): response_log.txt
```

## Logging

If you opt to log responses and errors, you'll be prompted to specify log file names. If the log files already exist, you’ll have the option to append to them or overwrite them.

## Custom Headers

When entering custom headers, use the format `key: value` and separate multiple headers with commas. For example:

```
X-API-Key: your_api_key, X-User-Agent: MyUserAgent
```
