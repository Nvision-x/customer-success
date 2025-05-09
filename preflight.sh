#!/bin/bash

# =========================================
# NVISION Endpoint Accessibility Checker
# Protect the jewels. Purge the junk.
# =========================================

# Text colors for better readability
RESET="\033[0m"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLACK="\033[30m"
TEAL="\033[38;5;43m"  # Brighter teal color
DGRAY="\033[38;5;239m"  # More accurate dark gray
WHITE="\033[37m"  # Bright white
NC='\033[0m' # No Color

# Display help information
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Check accessibility of required NVISION endpoints."
    echo
    echo "Options:"
    echo "  -f, --full     Display full report of all endpoints"
    echo "  -h, --help     Display this help message and exit"
    echo
    echo "By default, only inaccessible endpoints are shown."
    echo
    echo "Each endpoint check can have an expected HTTP response code."
    echo "If an endpoint returns a different code than expected, it will be marked as an issue."
    echo "You can modify the script to change expected response codes for specific endpoints."
    exit 0
}

# Display the NVISION ASCII logo
display_logo() {
    clear
    echo -e "${WHITE} ███╗   ██╗██╗   ██╗██╗███████╗██╗ ██████╗ ███╗   ██╗         "
    echo -e "${WHITE} ████╗  ██║██║   ██║██║██╔════╝██║██╔═══██╗████╗  ██║         "
    echo -e "${WHITE} ██╔██╗ ██║██║   ██║██║███████╗██║██║   ██║██╔██╗ ██║ ${TEAL}██╗ ██╗"
    echo -e "${WHITE} ██║╚██╗██║╚██╗ ██╔╝██║╚════██║██║██║   ██║██║╚██╗██║ ${TEAL}  ██╔╝ "
    echo -e "${WHITE} ██║ ╚████║ ╚████╔╝ ██║███████║██║╚██████╔╝██║ ╚████║ ${TEAL}██╔╝██╗"
    echo -e "${WHITE} ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ${TEAL}╚═╝ ╚═╝"
    echo -e "${WHITE}                                                              "
    echo -e ""
    echo -e "${DGRAY}                     Protect. Purge. Prosper.                 "
    echo -e "${RESET}"
}

# Display the header
display_header() {
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}       ENDPOINT ACCESSIBILITY CHECKER${NC}"
    echo -e "${YELLOW}===============================================${NC}\n"
}

# Function to check if an endpoint is accessible
check_endpoint() {
    local endpoint="$1"
    local port="$2"
    local purpose="$3"
    local expected_code="$4"  # Expected HTTP status code (e.g., 200, 404)
    local timeout=5
    local status=0
    local response_code=""
    
    # If no expected code is provided, default to 200
    if [ -z "$expected_code" ]; then
        expected_code="200"
    fi
    
    # Special value "any" means any response code is acceptable
    if [ "$expected_code" = "any" ]; then
        # Just check if the endpoint is reachable
        if curl --output /dev/null --silent --max-time "$timeout" "$endpoint"; then
            status=0 # Accessible
            response_code="any code"
        else
            status=1 # Not accessible
            response_code="unreachable"
        fi
    else
        # Check with specific expected code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$endpoint")
        
        # Check if the response code matches the expected code
        if [ "$response_code" = "$expected_code" ]; then
            status=0 # Code matches expected
        else
            status=1 # Code doesn't match expected
        fi
    fi
    
    # Save the result to our arrays for later reporting
    endpoints+=("$endpoint")
    ports+=("$port")
    purposes+=("$purpose")
    expected_codes+=("$expected_code")
    response_codes+=("$response_code")
    statuses+=($status)
    
    return $status
}

# Parse command line arguments
FULL_REPORT=0

# Process arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--full)
            FULL_REPORT=1
            shift
            ;;
        -h|--help)
            display_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage information."
            exit 1
            ;;
    esac
done

# Main function
main() {
    # Arrays to store endpoint information
    endpoints=()
    ports=()
    purposes=()
    expected_codes=()
    response_codes=()
    statuses=()
    failed_count=0
    total_count=0
    
    display_logo
    display_header
    
    # Check each endpoint and store results
    # Format: check_endpoint "URL" "PORT" "PURPOSE" "EXPECTED_CODE"
    # Use "any" for EXPECTED_CODE if any response code is acceptable
    
    # Standard 200 OK endpoints
    check_endpoint "https://s3.amazonaws.com" "443" "Hosts manifest and binary files from Replicated" "307" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://kurl-sh.s3.amazonaws.com" "443" "Hosts manifest and binary files from Replicated" "403" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://registry.replicated.com/" "443" "Private replicated container" "any" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://proxy.replicated.com/" "443" "Replicated proxy to allow pull Nx image from Docker Hub" "401" || ((failed_count++))
    ((total_count++))
    
    # Example of an endpoint where 404 is expected and acceptable
    check_endpoint "https://kurl.sh/" "443" "Shorted URL from Replicated to download Kubernetes base image components" "any" || ((failed_count++))
    ((total_count++))
    
    # Example of an endpoint where any response code is acceptable (just checking reachability)
    check_endpoint "https://s3.kurl.sh" "443" "Shorted URL from Replicated to download Kubernetes base image components" "any" || ((failed_count++))
    ((total_count++))
    
    # Continue with other endpoints (adjust expected codes as needed)
    check_endpoint "https://k8s.kurl.sh" "443" "Shorted URL from Replicated to download Kubernetes base image components" "200" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://docker.io/" "443" "Private registry for Nx images & Docker website" "any" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://index.docker.io" "443" "Private registry for Nx images & Docker website" "301" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://cdn.auth0.com" "443" "Authentication service for Docker" "200" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://registry.k8s.io" "443" "Kubernetes registry" "307" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://k8s.gcr.io" "443" "Kubernetes registry" "302" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://us-central1-docker.pkg.dev" "443" "Docker package registry" "302" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://api.replicated.com" "443" "Replicate API to build packages, updates, etc" "404" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://api.github.com" "443" "API to interact with GitHub" "200" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://github.com" "443" "GitHub website" "200" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://raw.githubusercontent.com" "443" "GitHub raw content" "301" || ((failed_count++))
    ((total_count++))
    
    check_endpoint "https://replicated.app" "443" "Web interface for Replicated" "200" || ((failed_count++))
    ((total_count++))
    
    # Display results based on the chosen mode
    if [ $failed_count -eq 0 ]; then
        echo -e "${GREEN}OK${NC} - All endpoints are accessible with expected response codes."
    else
        echo -e "${RED}ISSUES FOUND${NC} - $failed_count of $total_count endpoints have issues."
        echo
        
        # Display failed endpoints
        echo -e "${YELLOW}The following endpoints have issues:${NC}"
        echo
        
        for i in "${!endpoints[@]}"; do
            if [ ${statuses[$i]} -eq 1 ]; then
                echo -e "Endpoint: ${YELLOW}${endpoints[$i]}${NC}"
                echo -e "Port: ${BLUE}${ports[$i]}${NC}"
                echo -e "Purpose: ${WHITE}${purposes[$i]}${NC}"
                if [ "${expected_codes[$i]}" = "any" ]; then
                    echo -e "Expected: ${GREEN}Any response code${NC}"
                else
                    echo -e "Expected: ${GREEN}HTTP ${expected_codes[$i]}${NC}"
                fi
                echo -e "Received: ${RED}HTTP ${response_codes[$i]}${NC}"
                echo -e "Status: ${RED}FAILED ✗${NC}"
                echo
            fi
        done
    fi
    
    # If full report is requested, show all endpoints
    if [ $FULL_REPORT -eq 1 ]; then
        echo -e "\n${YELLOW}Full Endpoint Report:${NC}"
        echo
        
        for i in "${!endpoints[@]}"; do
            echo -e "Endpoint: ${YELLOW}${endpoints[$i]}${NC}"
            echo -e "Port: ${BLUE}${ports[$i]}${NC}"
            echo -e "Purpose: ${WHITE}${purposes[$i]}${NC}"
            
            if [ "${expected_codes[$i]}" = "any" ]; then
                echo -e "Expected: ${GREEN}Any response code${NC}"
            else
                echo -e "Expected: ${GREEN}HTTP ${expected_codes[$i]}${NC}"
            fi
            
            if [ ${statuses[$i]} -eq 0 ]; then
                echo -e "Received: ${GREEN}HTTP ${response_codes[$i]}${NC}"
                echo -e "Status: ${GREEN}SUCCESS ✓${NC}"
            else
                echo -e "Received: ${RED}HTTP ${response_codes[$i]}${NC}"
                echo -e "Status: ${RED}FAILED ✗${NC}"
            fi
            echo
        done
    fi
    
    echo -e "${BLUE}NVISION${NC} - ${WHITE}Protect the jewels. Purge the junk.${NC}"
}

# Run the main function
main
