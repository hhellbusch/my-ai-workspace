#!/bin/bash
#
# Test runner for S3 credential filtering examples
#
# Usage:
#   ./test_examples.sh              # Run all examples
#   ./test_examples.sh simple       # Run only simple example
#   ./test_examples.sh patterns     # Run only patterns example
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored header
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if ansible-playbook is available
if ! command -v ansible-playbook &> /dev/null; then
    print_error "ansible-playbook not found. Please install Ansible."
    exit 1
fi

print_success "Found ansible-playbook: $(ansible-playbook --version | head -n 1)"

# Determine which examples to run
RUN_ALL=true
RUN_SIMPLE=false
RUN_PATTERNS=false
RUN_PRACTICAL=false
RUN_ADVANCED=false

if [ $# -gt 0 ]; then
    RUN_ALL=false
    for arg in "$@"; do
        case $arg in
            simple)
                RUN_SIMPLE=true
                ;;
            patterns)
                RUN_PATTERNS=true
                ;;
            practical)
                RUN_PRACTICAL=true
                ;;
            advanced)
                RUN_ADVANCED=true
                ;;
            all)
                RUN_ALL=true
                ;;
            *)
                print_error "Unknown example: $arg"
                echo "Valid options: simple, patterns, practical, advanced, all"
                exit 1
                ;;
        esac
    done
fi

# Set flags if running all
if [ "$RUN_ALL" = true ]; then
    RUN_SIMPLE=true
    RUN_PATTERNS=true
    RUN_PRACTICAL=true
    RUN_ADVANCED=true
fi

# Track results
PASSED=0
FAILED=0
TOTAL=0

# Function to run a playbook
run_playbook() {
    local name=$1
    local playbook=$2
    local extra_args=${3:-}
    
    print_header "Running: $name"
    TOTAL=$((TOTAL + 1))
    
    if ansible-playbook "$playbook" $extra_args; then
        print_success "$name completed successfully"
        PASSED=$((PASSED + 1))
        return 0
    else
        print_error "$name failed"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Run examples
echo ""
print_info "Starting test run..."
print_info "Working directory: $SCRIPT_DIR"
echo ""

if [ "$RUN_SIMPLE" = true ]; then
    run_playbook "Simple Filter Example" "simple_filter.yml"
fi

if [ "$RUN_PATTERNS" = true ]; then
    run_playbook "Filter Patterns Example" "filter_patterns.yml"
fi

if [ "$RUN_PRACTICAL" = true ]; then
    run_playbook "Practical Example (Mock Data)" "practical_example.yml" "-e use_mock_data=true"
fi

if [ "$RUN_ADVANCED" = true ]; then
    run_playbook "Advanced Filters Example" "advanced_filters.yml"
fi

# Print summary
print_header "Test Summary"
echo -e "Total examples run: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
else
    echo -e "Failed: ${FAILED}"
fi
echo ""

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    print_error "Some tests failed"
    exit 1
else
    print_success "All tests passed!"
    exit 0
fi

