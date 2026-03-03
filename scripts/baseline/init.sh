#!/bin/bash
#
# Homelab Platform - Baseline Initialization Script
#
# This script provides unified post-creation baseline initialization for all VMs and LXCs.
# It implements "create and ready-to-use" functionality by addressing common pain points.
#
# Features:
# - Idempotent execution (safe to run multiple times)
# - Modular design for easy maintenance
# - Works on both VMs and LXCs
# - Comprehensive logging
#
# Usage:
#   sudo ./init.sh
#   sudo ./init.sh --dry-run
#   curl -fsSL https://raw.githubusercontent.com/your-repo/homelab-platform/main/scripts/baseline/init.sh | sudo bash
#

set -euo pipefail

# Global variables
DRY_RUN=false

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULES_DIR="${SCRIPT_DIR}/modules"
readonly LOG_FILE="/var/log/homelab-baseline-init.log"
readonly LOCK_FILE="/var/lock/homelab-baseline-init.lock"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ "$DRY_RUN" == true ]]; then
        # In dry-run mode, try to log but don't fail if we can't
        echo -e "${timestamp} [${level}] [DRY-RUN] ${message}" | tee -a "${LOG_FILE}" 2>/dev/null || \
        echo -e "${timestamp} [${level}] [DRY-RUN] ${message}"
    else
        echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
    fi
}

log_info() {
    log "INFO" "$@"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}[INFO] [DRY-RUN]${NC} $*"
    else
        echo -e "${BLUE}[INFO]${NC} $*"
    fi
}

log_warn() {
    log "WARN" "$@"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[WARN] [DRY-RUN]${NC} $*"
    else
        echo -e "${YELLOW}[WARN]${NC} $*"
    fi
}

log_error() {
    log "ERROR" "$@"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${RED}[ERROR] [DRY-RUN]${NC} $*"
    else
        echo -e "${RED}[ERROR]${NC} $*"
    fi
}

log_success() {
    log "SUCCESS" "$@"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${GREEN}[SUCCESS] [DRY-RUN]${NC} $*"
    else
        echo -e "${GREEN}[SUCCESS]${NC} $*"
    fi
}

# Export logging functions for use in sourced modules
export -f log log_info log_warn log_error log_success

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                export DRY_RUN
                log_info "Dry-run mode enabled - no system changes will be made"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Homelab Platform - Baseline Initialization Script

Usage: $0 [OPTIONS]

Options:
  --dry-run    Run in dry-run mode (simulate without making changes)
  --help, -h   Show this help message

Description:
  This script provides unified post-creation baseline initialization for all VMs and LXCs.
  It implements "create and ready-to-use" functionality by addressing common pain points.

Examples:
  sudo $0                    # Normal execution
  sudo $0 --dry-run         # Dry-run mode (safe testing)

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Create lock file to prevent concurrent execution
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another instance is already running (PID: $lock_pid)"
            exit 1
        else
            log_warn "Stale lock file found, removing it"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Remove lock file on exit
cleanup() {
    rm -f "$LOCK_FILE"
}

# Execute a module with error handling
execute_module() {
    local module_file="$1"
    local module_name=$(basename "$module_file" .sh)

    log_info "Executing module: $module_name"

    if [[ ! -f "$module_file" ]]; then
        log_error "Module file not found: $module_file"
        return 1
    fi

    if [[ ! -x "$module_file" ]]; then
        log_warn "Making module executable: $module_file"
        chmod +x "$module_file"
    fi

    # Execute module in a subshell to isolate environment
    if (
        set -euo pipefail
        source "$module_file"
    ); then
        log_success "Module completed successfully: $module_name"
        return 0
    else
        log_error "Module failed: $module_name"
        return 1
    fi
}

# Main execution function
main() {
    log_info "Starting Homelab Platform baseline initialization"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "🔍 DRY-RUN MODE: No system changes will be made"
        log_info "This mode validates configuration and simulates execution"
    fi

    log_info "Hostname: $(hostname)"
    log_info "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
    log_info "Kernel: $(uname -r)"

    # Check prerequisites (skip root check in dry-run mode)
    if [[ "$DRY_RUN" != true ]]; then
        check_root
        acquire_lock
    else
        log_info "Skipping root check and lock acquisition in dry-run mode"
    fi

    # Ensure log directory exists
    if [[ "$DRY_RUN" != true ]]; then
        mkdir -p "$(dirname "$LOG_FILE")"
    else
        log_info "Would create log directory: $(dirname "$LOG_FILE")"
    fi

    # Set trap for cleanup (only in normal mode)
    if [[ "$DRY_RUN" != true ]]; then
        trap cleanup EXIT INT TERM
    fi

    # Execute modules in order
    local modules=(
        "01-apt-sources.sh"
        "02-packages.sh"
        "03-shell-env.sh"
        "04-motd.sh"
        "05-system.sh"
        "06-security.sh"
    )

    local failed_modules=()
    local total_modules=${#modules[@]}
    local completed_modules=0

    for module in "${modules[@]}"; do
        local module_path="${MODULES_DIR}/${module}"

        if execute_module "$module_path"; then
            ((completed_modules++))
        else
            failed_modules+=("$module")
        fi
    done

    # Summary
    log_info "Baseline initialization completed"
    log_info "Modules executed: $completed_modules/$total_modules"

    if [[ ${#failed_modules[@]} -eq 0 ]]; then
        log_success "All modules completed successfully!"
        log_info "System is ready for use. Please reboot or re-login to apply all changes."
    else
        log_warn "Some modules failed: ${failed_modules[*]}"
        log_warn "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main
fi