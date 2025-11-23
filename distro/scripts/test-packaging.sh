#!/bin/bash
# Manual testing script for DMS packaging
# Tests OBS (Debian/openSUSE) and PPA (Ubuntu) workflows
# Usage: ./distro/test-packaging.sh [obs|ppa|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$DISTRO_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

TEST_MODE="${1:-all}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DMS Packaging Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: OBS Upload (Debian + openSUSE)
if [[ "$TEST_MODE" == "obs" ]] || [[ "$TEST_MODE" == "all" ]]; then
    echo "═══════════════════════════════════════════════════════════════════"
    echo "TEST 1: OBS Upload (Debian + openSUSE)"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    OBS_SCRIPT="$SCRIPT_DIR/obs-upload.sh"
    
    if [[ ! -f "$OBS_SCRIPT" ]]; then
        error "OBS script not found: $OBS_SCRIPT"
        exit 1
    fi
    
    info "OBS script location: $OBS_SCRIPT"
    info "Available packages: dms, dms-git"
    echo ""
    
    warn "This will upload to OBS (home:AvengeMedia)"
    read -p "Continue with OBS test? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Select package to test:"
        echo "  1. dms (stable)"
        echo "  2. dms-git (nightly)"
        echo "  3. all (both packages)"
        read -p "Choice [1]: " -n 1 -r PKG_CHOICE
        echo
        echo ""
        
        PKG_CHOICE="${PKG_CHOICE:-1}"
        
        cd "$REPO_ROOT"
        
        case "$PKG_CHOICE" in
            1)
                info "Testing OBS upload for 'dms' package..."
                bash "$OBS_SCRIPT" dms "Test packaging update"
                ;;
            2)
                info "Testing OBS upload for 'dms-git' package..."
                bash "$OBS_SCRIPT" dms-git "Test packaging update"
                ;;
            3)
                info "Testing OBS upload for all packages..."
                bash "$OBS_SCRIPT" all "Test packaging update"
                ;;
            *)
                error "Invalid choice"
                exit 1
                ;;
        esac
        
        echo ""
        success "OBS test completed"
        echo ""
        info "Check build status: https://build.opensuse.org/project/monitor/home:AvengeMedia"
    else
        warn "OBS test skipped"
    fi
    
    echo ""
fi

# Test 2: PPA Upload (Ubuntu)
if [[ "$TEST_MODE" == "ppa" ]] || [[ "$TEST_MODE" == "all" ]]; then
    echo "═══════════════════════════════════════════════════════════════════"
    echo "TEST 2: PPA Upload (Ubuntu)"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    PPA_SCRIPT="$DISTRO_DIR/ubuntu/ppa/create-and-upload.sh"
    
    if [[ ! -f "$PPA_SCRIPT" ]]; then
        error "PPA script not found: $PPA_SCRIPT"
        exit 1
    fi
    
    info "PPA script location: $PPA_SCRIPT"
    info "Available PPAs: dms, dms-git"
    info "Ubuntu series: questing (25.10)"
    echo ""
    
    warn "This will upload to Launchpad PPA (ppa:avengemedia/dms)"
    read -p "Continue with PPA test? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Select package to test:"
        echo "  1. dms (stable)"
        echo "  2. dms-git (nightly)"
        read -p "Choice [1]: " -n 1 -r PKG_CHOICE
        echo
        echo ""
        
        PKG_CHOICE="${PKG_CHOICE:-1}"
        
        case "$PKG_CHOICE" in
            1)
                info "Testing PPA upload for 'dms' package..."
                DMS_PKG="$DISTRO_DIR/ubuntu/dms"
                PPA_NAME="dms"
                ;;
            2)
                info "Testing PPA upload for 'dms-git' package..."
                DMS_PKG="$DISTRO_DIR/ubuntu/dms-git"
                PPA_NAME="dms-git"
                ;;
            *)
                error "Invalid choice"
                exit 1
                ;;
        esac
        
        echo ""
        
        if [[ ! -d "$DMS_PKG" ]]; then
            error "DMS package directory not found: $DMS_PKG"
            exit 1
        fi
        
        bash "$PPA_SCRIPT" "$DMS_PKG" "$PPA_NAME" questing
        
        echo ""
        success "PPA test completed"
        echo ""
        info "Check build status: https://launchpad.net/~avengemedia/+archive/ubuntu/dms/+packages"
    else
        warn "PPA test skipped"
    fi
    
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
