#!/bin/bash
#
# Module: Basic Packages Installation
# Purpose: Install essential tools and utilities for homelab operations
#

# Module configuration
readonly MODULE_NAME="packages"

# Essential packages list (按功能分组)
readonly ESSENTIAL_PACKAGES=(
    # 网络工具
    "curl"
    "wget"
    "dnsutils"

    # 编辑器和开发工具
    "vim"
    "git"

    # 系统监控和管理
    "htop"
    "tree"
    "ncdu"
    "rsync"

    # 压缩和解压工具
    "unzip"

    # JSON处理和Shell增强
    "jq"
    "bash-completion"

    # 终端复用器
    "tmux"

    # 系统信息
    "lsb-release"

    # 加密和安全
    "gnupg"
)

# Check if package is installed
is_package_installed() {
    local package="$1"
    dpkg -l "$package" 2>/dev/null | grep -q "^ii"
}

# Install a single package
install_package() {
    local package="$1"

    if is_package_installed "$package"; then
        log_info "Package already installed: $package"
        return 0
    fi

    log_info "Installing package: $package"
    if DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" >/dev/null 2>&1; then
        log_success "Successfully installed: $package"
        return 0
    else
        log_error "Failed to install: $package"
        return 1
    fi
}

# Update package cache
update_package_cache() {
    log_info "Updating package cache"
    if apt-get update -qq >/dev/null 2>&1; then
        log_success "Package cache updated successfully"
        return 0
    else
        log_error "Failed to update package cache"
        return 1
    fi
}

# Install all essential packages
install_essential_packages() {
    local failed_packages=()
    local installed_count=0
    local total_packages=${#ESSENTIAL_PACKAGES[@]}

    log_info "Installing $total_packages essential packages"

    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        if install_package "$package"; then
            ((installed_count++))
        else
            failed_packages+=("$package")
        fi
    done

    log_info "Package installation summary: $installed_count/$total_packages successful"

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi

    return 0
}

# Verify critical packages are working
verify_packages() {
    log_info "Verifying critical package installations"

    local critical_commands=(
        "curl --version"
        "vim --version"
        "git --version"
        "htop --version"
        "jq --version"
        "tmux -V"
    )

    local failed_verifications=()

    for cmd in "${critical_commands[@]}"; do
        local cmd_name=$(echo "$cmd" | cut -d' ' -f1)
        if command -v "$cmd_name" >/dev/null 2>&1; then
            log_success "Verified: $cmd_name"
        else
            log_error "Verification failed: $cmd_name"
            failed_verifications+=("$cmd_name")
        fi
    done

    if [[ ${#failed_verifications[@]} -gt 0 ]]; then
        log_error "Package verification failed for: ${failed_verifications[*]}"
        return 1
    fi

    log_success "All critical packages verified successfully"
    return 0
}

# Clean up package cache
cleanup_package_cache() {
    log_info "Cleaning up package cache"
    apt-get autoremove -y >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    log_success "Package cache cleaned up"
}

# Main module execution
main() {
    log_info "Starting essential packages installation"

    # Update package cache first
    if ! update_package_cache; then
        log_error "Cannot proceed without updated package cache"
        return 1
    fi

    # Install essential packages
    if ! install_essential_packages; then
        log_error "Some packages failed to install"
        return 1
    fi

    # Verify installations
    if ! verify_packages; then
        log_error "Package verification failed"
        return 1
    fi

    # Clean up
    cleanup_package_cache

    log_success "Essential packages installation completed successfully"
    return 0
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi