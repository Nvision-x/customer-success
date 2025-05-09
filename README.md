# NVISION Endpoint Accessibility Checker

A Bash script to verify if the required NVISION endpoints are accessible on your network.

```
 ███╗   ██╗██╗   ██╗██╗███████╗██╗ ██████╗ ███╗   ██╗         
 ████╗  ██║██║   ██║██║██╔════╝██║██╔═══██╗████╗  ██║         
 ██╔██╗ ██║██║   ██║██║███████╗██║██║   ██║██╔██╗ ██║ ██╗ ██╗
 ██║╚██╗██║╚██╗ ██╔╝██║╚════██║██║██║   ██║██║╚██╗██║   ██╔╝ 
 ██║ ╚████║ ╚████╔╝ ██║███████║██║╚██████╔╝██║ ╚████║ ██╔╝██╗
 ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═╝ ╚═╝
                                                              
                     Protect. Purge. Prosper.                 
```

## What This Script Does

This tool allows you to check if all required NVISION endpoints are accessible from your system and respond with the expected HTTP status codes. It verifies connectivity to essential services including:

- AWS S3 buckets
- Replicated services
- Docker registries
- Kubernetes repositories
- GitHub APIs

All endpoints are checked using HTTPS (port 443) to ensure secure connectivity.

## Endpoints Checked

| URL | Port | Purpose | Expected Response |
|-----|------|---------|-------------------|
| https://s3.amazonaws.com | 443 | Hosts manifest and binary files from Replicated | 200 OK |
| https://kurl-sh.s3.amazonaws.com | 443 | Hosts manifest and binary files from Replicated | 200 OK |
| https://registry.replicated.com/ | 443 | Private replicated container | 200 OK |
| https://proxy.replicated.com/ | 443 | Replicated proxy to allow pull Nx image from Docker Hub | 200 OK |
| https://kurl.sh/ | 443 | Shorted URL from Replicated to download Kubernetes base image components | 404 Not Found |
| https://s3.kurl.sh | 443 | Shorted URL from Replicated to download Kubernetes base image components | Any |
| https://k8s.kurl.sh | 443 | Shorted URL from Replicated to download Kubernetes base image components | 200 OK |
| https://docker.io/ | 443 | Private registry for Nx images & Docker website | 200 OK |
| https://index.docker.io | 443 | Private registry for Nx images & Docker website | 200 OK |
| https://cdn.auth0.com | 443 | Authentication service for Docker | 200 OK |
| https://registry.k8s.io | 443 | Kubernetes registry | 200 OK |
| https://k8s.gcr.io | 443 | Kubernetes registry | 200 OK |
| https://us-central1-docker.pkg.dev | 443 | Docker package registry | 200 OK |
| https://api.replicated.com | 443 | Replicate API to build packages, updates, etc | 200 OK |
| https://api.github.com | 443 | API to interact with GitHub | 200 OK |
| https://github.com | 443 | GitHub website | 200 OK |
| https://raw.githubusercontent.com | 443 | GitHub raw content | 200 OK |
| https://replicated.app | 443 | Web interface for Replicated | 200 OK |

## Quick Start

Run the script directly from GitHub with a single command:

```bash
curl -s https://raw.githubusercontent.com/Nvision-x/customer-success/main/preflight.sh | bash
```

For the full report option:

```bash
curl -s https://raw.githubusercontent.com/Nvision-x/customer-success/main/preflight.sh | bash -s -- --full
```

## How to Use

The script has several run options:

1. **Default Mode** - Only shows endpoints with issues:
   ```
   ./check_endpoints.sh
   ```
   - If all endpoints are accessible with expected response codes, you'll only see "OK"
   - If any endpoints have issues, only the problematic ones will be displayed

2. **Full Report Mode** - Shows the status of all endpoints:
   ```
   ./check_endpoints.sh --full
   ```
   or
   ```
   ./check_endpoints.sh -f
   ```

3. **Help** - Display usage information:
   ```
   ./check_endpoints.sh --help
   ```
   or
   ```
   ./check_endpoints.sh -h
   ```

## Understanding the Results

The script will check each endpoint and compare the HTTP response code with the expected code:
- **SUCCESS ✓**: The endpoint responded with the expected HTTP status code
- **FAILED ✗**: The endpoint either couldn't be reached or responded with an unexpected status code

For each displayed endpoint, you'll see:
- The URL being checked
- The port being used
- The purpose of the endpoint
- The expected HTTP status code
- The received HTTP status code
- The overall status (SUCCESS or FAILED)

## Customizing Expected Response Codes

The script now supports custom expected HTTP response codes for each endpoint. This is particularly useful when:
- Some endpoints are expected to return 404 Not Found
- Certain endpoints should be validated solely for reachability, regardless of status code
- Different environments might have different expected responses

To modify the expected response code for an endpoint, edit the script and change the fourth parameter in the `check_endpoint` function call:

```bash
# Format: check_endpoint "URL" "PORT" "PURPOSE" "EXPECTED_CODE"
check_endpoint "https://example.com" "443" "Example endpoint" "200"  # Expects HTTP 200 OK
check_endpoint "https://api.example.com/missing" "443" "Missing endpoint" "404"  # Expects HTTP 404 Not Found
check_endpoint "https://status.example.com" "443" "Status page" "any"  # Accepts any response code
```

Special values:
- Numeric values (e.g., "200", "404", "500"): The endpoint must return this exact HTTP status code
- "any": The endpoint only needs to be reachable; any response code is acceptable

## Troubleshooting

If you see "FAILED" for any endpoint:

1. **Different Response Code Than Expected**:
   - Check if the expected code in the script is correct for that endpoint
   - The service might have changed its behavior
   - Consider updating the expected code if the change is permanent

2. **Unreachable Endpoints**:
   - Check your internet connection
   - Verify your firewall rules allow outbound HTTPS traffic (port 443)
   - Check if your company network blocks access to certain domains

Common solutions:
- Contact your network administrator to allow access to the required domains
- Configure your proxy settings if you're behind a corporate proxy
- Check your DNS settings to ensure proper domain resolution

## Advanced Usage

### Adding Custom Endpoints

If you need to check additional endpoints, you can modify the script by adding new lines following this pattern:

```bash
check_endpoint "https://your-endpoint.com" "443" "Description of the endpoint" "expected_code" || ((failed_count++))
((total_count++))
```

Replace `expected_code` with the HTTP status code you expect (like "200", "404") or use "any" if you only care about reachability.

### Saving Results to a File

You can save the output to a file for later review:

```
./check_endpoints.sh --full > endpoint_report.txt
```

## Need Help?

If you're experiencing issues with connectivity to these endpoints:
1. Run the script with the `--full` flag to get a complete report
2. Share the results with your network administrator or NVISION support team
3. Include details about your network environment (proxy settings, firewalls, etc.)

This will help them troubleshoot any connectivity issues efficiently.
