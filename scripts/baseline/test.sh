#!/bin/bash
#
# Homelab Platform - Simple Test Script
# 基线脚本简单测试
#

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}Homelab Platform - Baseline Test Suite${NC}"
echo "======================================"
echo

# Test 1: Syntax validation
echo -e "${BLUE}Test 1: Syntax Validation${NC}"
((TOTAL_TESTS++))

syntax_errors=0
echo "  Checking init.sh..."
if bash -n "${SCRIPT_DIR}/init.sh" 2>/dev/null; then
    echo -e "    ${GREEN}✓ init.sh${NC}"
else
    echo -e "    ${RED}✗ init.sh${NC}"
    ((syntax_errors++))
fi

for script in "${MODULES_DIR}"/*.sh; do
    if [[ -f "$script" ]]; then
        script_name=$(basename "$script")
        echo "  Checking $script_name..."
        if bash -n "$script" 2>/dev/null; then
            echo -e "    ${GREEN}✓ $script_name${NC}"
        else
            echo -e "    ${RED}✗ $script_name${NC}"
            ((syntax_errors++))
        fi
    fi
done

if [[ $syntax_errors -eq 0 ]]; then
    echo -e "${GREEN}✓ All scripts pass syntax validation${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${RED}✗ $syntax_errors scripts have syntax errors${NC}"
fi
echo

# Test 2: Function export verification
echo -e "${BLUE}Test 2: Function Export Verification${NC}"
((TOTAL_TESTS++))

if bash -c "source '${SCRIPT_DIR}/init.sh' 2>/dev/null && type log_info >/dev/null 2>&1"; then
    echo -e "${GREEN}✓ Logging functions are exported${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${RED}✗ Function export failed${NC}"
fi
echo

# Test 3: Module loading test
echo -e "${BLUE}Test 3: Module Loading Test${NC}"
((TOTAL_TESTS++))

load_errors=0
for module in "${MODULES_DIR}"/*.sh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module" .sh)
        echo "  Testing $module_name..."
        if bash -c "source '${SCRIPT_DIR}/init.sh' 2>/dev/null && source '$module' 2>/dev/null" >/dev/null 2>&1; then
            echo -e "    ${GREEN}✓ $module_name${NC}"
        else
            echo -e "    ${RED}✗ $module_name${NC}"
            ((load_errors++))
        fi
    fi
done

if [[ $load_errors -eq 0 ]]; then
    echo -e "${GREEN}✓ All modules load successfully${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${RED}✗ $load_errors modules failed to load${NC}"
fi
echo

# Test 4: Dry-run functionality
echo -e "${BLUE}Test 4: Dry-run Functionality${NC}"
((TOTAL_TESTS++))

if timeout 3 "${SCRIPT_DIR}/init.sh" --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Help functionality works${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${RED}✗ Help functionality failed${NC}"
fi
echo

# Summary
echo "======================================"
echo -e "${BLUE}Test Summary:${NC}"
echo "  Total Tests: $TOTAL_TESTS"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed.${NC}"
    exit 1
fi