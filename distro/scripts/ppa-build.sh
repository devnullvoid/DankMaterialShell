#!/usr/bin/env bash
# Generic source package builder for DMS PPA packages
# Usage: ./create-source.sh <package-dir> [ubuntu-series]
#
# Example:
#   ./create-source.sh ../dms questing
#   ./create-source.sh ../dms-git questing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ $# -lt 1 ]; then
    error "Usage: $0 <package-dir> [ubuntu-series]"
    echo
    echo "Arguments:"
    echo "  package-dir     : Path to package directory (e.g., ../dms)"
    echo "  ubuntu-series   : Ubuntu series (optional, default: noble)"
    echo "                    Options: noble, jammy, oracular, mantic"
    echo
    echo "Examples:"
    echo "  $0 ../dms questing"
    echo "  $0 ../dms-git questing"
    exit 1
fi

PACKAGE_DIR="$1"
UBUNTU_SERIES="${2:-noble}"

if [ ! -d "$PACKAGE_DIR" ]; then
    error "Package directory not found: $PACKAGE_DIR"
    exit 1
fi

if [ ! -d "$PACKAGE_DIR/debian" ]; then
    error "No debian/ directory found in $PACKAGE_DIR"
    exit 1
fi

PACKAGE_DIR=$(cd "$PACKAGE_DIR" && pwd)
PACKAGE_NAME=$(basename "$PACKAGE_DIR")
PACKAGE_PARENT=$(dirname "$PACKAGE_DIR")

# Choose temp directory: use /tmp in CI, ~/tmp locally (keeps artifacts out of repo)
if [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${CI:-}" ]]; then
    TEMP_BASE="/tmp"
else
    TEMP_BASE="$HOME/tmp"
    mkdir -p "$TEMP_BASE"
fi

TEMP_WORK_DIR=$(mktemp -d "$TEMP_BASE/ppa_build_work_XXXXXX")
# Only auto-cleanup if not called from ppa-upload.sh (it will clean up after upload)
if [[ -z "${PPA_UPLOAD_SCRIPT:-}" ]]; then
    trap 'rm -rf "$TEMP_WORK_DIR"' EXIT
fi

info "Building source package for: $PACKAGE_NAME"
info "Package directory: $PACKAGE_DIR"
info "Working directory: $TEMP_WORK_DIR"
info "Target Ubuntu series: $UBUNTU_SERIES"
REQUIRED_FILES=(
    "debian/control"
    "debian/rules"
    "debian/changelog"
    "debian/copyright"
    "debian/source/format"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PACKAGE_DIR/$file" ]; then
        error "Required file missing: $file"
        exit 1
    fi
done

# Verify GPG key is set up
info "Checking GPG key setup..."
if ! gpg --list-secret-keys &>/dev/null; then
    error "No GPG secret keys found. Please set up GPG first!"
    error "See GPG_SETUP.md for instructions"
    exit 1
fi

success "GPG key found"

if ! command -v debuild &>/dev/null; then
    error "debuild not found. Install devscripts:"
    error "  sudo dnf install devscripts"
    exit 1
fi

cd "$PACKAGE_DIR"
CHANGELOG_VERSION=$(dpkg-parsechangelog -S Version)
SOURCE_NAME=$(dpkg-parsechangelog -S Source)

info "Source package: $SOURCE_NAME"
info "Version: $CHANGELOG_VERSION"

CHANGELOG_SERIES=$(dpkg-parsechangelog -S Distribution)
if [ "$CHANGELOG_SERIES" != "$UBUNTU_SERIES" ] && [ "$CHANGELOG_SERIES" != "UNRELEASED" ]; then
    warn "Changelog targets '$CHANGELOG_SERIES' but building for '$UBUNTU_SERIES'"
    warn "Consider updating changelog with: dch -r '' -D $UBUNTU_SERIES"
fi

# Check if this is a manual run or automated
IS_MANUAL=false
if [[ -n "${REBUILD_RELEASE:-}" ]]; then
    IS_MANUAL=true
    echo "==> Manual rebuild detected (REBUILD_RELEASE=$REBUILD_RELEASE)"
elif [[ -n "${FORCE_REBUILD:-}" ]] && [[ "${FORCE_REBUILD}" == "true" ]]; then
    IS_MANUAL=true
    echo "==> Manual workflow trigger detected (FORCE_REBUILD=true)"
elif [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
    IS_MANUAL=true
    echo "==> Manual workflow trigger detected (workflow_dispatch)"
elif [[ -z "${GITHUB_ACTIONS:-}" ]] && [[ -z "${CI:-}" ]]; then
    IS_MANUAL=true
    echo "==> Local/manual run detected (not in CI)"
fi

info "Copying package to working directory..."
cp -r "$PACKAGE_DIR" "$TEMP_WORK_DIR/"
WORK_PACKAGE_DIR="$TEMP_WORK_DIR/$PACKAGE_NAME"

if [ -f "$WORK_PACKAGE_DIR/debian/files" ]; then
    info "Removing old debian/files build artifact..."
    rm -f "$WORK_PACKAGE_DIR/debian/files"
fi

cd "$WORK_PACKAGE_DIR"
get_latest_tag() {
    local repo="$1"
    if command -v curl &>/dev/null; then
        LATEST_TAG=$(curl -s "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | grep '"tag_name":' | sed 's/.*"tag_name": "\(.*\)".*/\1/' | head -1)
        if [ -n "$LATEST_TAG" ]; then
            echo "$LATEST_TAG" | sed 's/^v//'
            return
        fi
    fi
    TEMP_REPO=$(mktemp -d "$TEMP_BASE/ppa_tag_XXXXXX")
    if git clone --depth=1 --quiet "https://github.com/$repo.git" "$TEMP_REPO" 2>/dev/null; then
        LATEST_TAG=$(cd "$TEMP_REPO" && git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "")
        rm -rf "$TEMP_REPO"
        echo "$LATEST_TAG"
    fi
}

IS_GIT_PACKAGE=false
GIT_REPO=""
SOURCE_DIR=""

if [[ "$PACKAGE_NAME" == *"-git" ]]; then
    IS_GIT_PACKAGE=true
fi

if grep -q "git clone" debian/rules 2>/dev/null; then
    IS_GIT_PACKAGE=true
    GIT_URL=$(grep -o "git clone.*https://github.com/[^/]*/[^/]*\.git" debian/rules 2>/dev/null | head -1 | sed 's/.*github\.com\///' | sed 's/\.git.*//' || echo "")
    if [ -n "$GIT_URL" ]; then
        GIT_REPO="$GIT_URL"
    fi
fi
case "$PACKAGE_NAME" in
dms-git)
    IS_GIT_PACKAGE=true
    GIT_REPO="AvengeMedia/DankMaterialShell"
    SOURCE_DIR="dms-git-repo"
    ;;
dms)
    GIT_REPO="AvengeMedia/DankMaterialShell"
    ;;
dms-greeter)
    GIT_REPO="AvengeMedia/DankMaterialShell"
    ;;
danksearch)
    GIT_REPO="AvengeMedia/danksearch"
    ;;
dgop)
    GIT_REPO="AvengeMedia/dgop"
    ;;
esac

# Handle stable packages - update changelog FIRST before downloads
if [ "$IS_GIT_PACKAGE" = false ] && [ -n "$GIT_REPO" ]; then
    info "Detected stable package: $PACKAGE_NAME"
    info "Fetching latest tag from $GIT_REPO..."

    LATEST_TAG=$(get_latest_tag "$GIT_REPO")
    if [ -n "$LATEST_TAG" ]; then
        SOURCE_FORMAT=$(head -1 debian/source/format 2>/dev/null || echo "3.0 (quilt)")
        CURRENT_VERSION=$(dpkg-parsechangelog -S Version 2>/dev/null || echo "")
        if [[ -n "${REBUILD_RELEASE:-}" ]]; then
            PPA_NUM=$REBUILD_RELEASE
            info "Using REBUILD_RELEASE=$REBUILD_RELEASE for PPA number"
        else
            PPA_NUM=1
        fi

        if [[ "$SOURCE_FORMAT" == *"native"* ]]; then
            BASE_VERSION="${LATEST_TAG}"
            if [[ -z "${REBUILD_RELEASE:-}" ]] && [[ "$CURRENT_VERSION" =~ ^${LATEST_TAG}ppa([0-9]+)$ ]]; then
                if [[ "$IS_MANUAL" == true ]] && [[ -z "${GITHUB_ACTIONS:-}" ]] && [[ -z "${CI:-}" ]]; then
                    # Only error for true local manual runs, not CI/workflow runs
                    error "Same version detected ($CURRENT_VERSION) but no rebuild number specified"
                    error "To rebuild, explicitly specify a rebuild number:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME 2"
                    error "or use flag syntax:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME --rebuild=2"
                    exit 1
                else
                    info "Detected rebuild of same version (current: $CURRENT_VERSION). No changes needed, skipping."
                    success "No changes needed (version matches)."
                    exit 0
                fi
            elif [[ -z "${REBUILD_RELEASE:-}" ]]; then
                info "New version or first build, using PPA number $PPA_NUM"
            fi
            NEW_VERSION="${BASE_VERSION}ppa${PPA_NUM}"
        else
            BASE_VERSION="${LATEST_TAG}-1"
            ESCAPED_BASE=$(echo "$BASE_VERSION" | sed 's/\./\\./g' | sed 's/-/\\-/g')
            if [[ -z "${REBUILD_RELEASE:-}" ]] && [[ "$CURRENT_VERSION" =~ ^${ESCAPED_BASE}ppa([0-9]+)$ ]]; then
                if [[ "$IS_MANUAL" == true ]] && [[ -z "${GITHUB_ACTIONS:-}" ]] && [[ -z "${CI:-}" ]]; then
                    # Only error for true local manual runs, not CI/workflow runs
                    error "Same version detected ($CURRENT_VERSION) but no rebuild number specified"
                    error "To rebuild, explicitly specify a rebuild number:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME 2"
                    error "or use flag syntax:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME --rebuild=2"
                    exit 1
                else
                    info "Detected rebuild of same version (current: $CURRENT_VERSION). No changes needed, skipping."
                    success "No changes needed (version matches)."
                    exit 0
                fi
            elif [[ -z "${REBUILD_RELEASE:-}" ]]; then
                info "New version or first build, using PPA number $PPA_NUM"
            fi
            NEW_VERSION="${BASE_VERSION}ppa${PPA_NUM}"
        fi

        if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
            if [ "$PPA_NUM" -gt 1 ]; then
                info "Updating changelog for rebuild (PPA number incremented to $PPA_NUM)"
            else
                info "Updating changelog to latest tag: $LATEST_TAG"
            fi
            if [ "$PPA_NUM" -gt 1 ]; then
                CHANGELOG_MSG="Rebuild for packaging fixes (ppa${PPA_NUM})"
            else
                CHANGELOG_MSG="Upstream release ${LATEST_TAG}"
            fi

            # Single changelog entry (full history available on Launchpad)
            cat >debian/changelog <<EOF
${SOURCE_NAME} (${NEW_VERSION}) ${UBUNTU_SERIES}; urgency=medium

  * ${CHANGELOG_MSG}

 -- Avenge Media <AvengeMedia.US@gmail.com>  $(date -R)
EOF
            success "Version updated to $NEW_VERSION"
            CHANGELOG_VERSION=$(dpkg-parsechangelog -S Version)

            info "Writing updated changelog back to repository..."
            cp debian/changelog "$PACKAGE_DIR/debian/changelog"
            success "Changelog written back to $PACKAGE_DIR/debian/changelog"
        else
            info "Version already at latest tag: $LATEST_TAG"
        fi
    else
        warn "Could not determine latest tag for $GIT_REPO, using existing version"
    fi

    # Download binaries/source using the updated version from changelog
    VERSION=$(dpkg-parsechangelog -S Version | sed 's/-[^-]*$//' | sed 's/ppa[0-9]*$//')

    case "$PACKAGE_NAME" in
    dms)
        info "Downloading pre-built binaries and source for dms..."
        if [ ! -f "dms-distropkg-amd64.gz" ]; then
            info "Downloading dms binary for amd64..."
            if wget -O dms-distropkg-amd64.gz "https://github.com/AvengeMedia/DankMaterialShell/releases/download/v${VERSION}/dms-distropkg-amd64.gz"; then
                success "amd64 binary downloaded"
            else
                error "Failed to download dms-distropkg-amd64.gz"
                exit 1
            fi
        fi

        if [ ! -f "dms-source.tar.gz" ]; then
            info "Downloading dms source for QML files..."
            if wget -O dms-source.tar.gz "https://github.com/AvengeMedia/DankMaterialShell/archive/refs/tags/v${VERSION}.tar.gz"; then
                success "source tarball downloaded"
            else
                error "Failed to download dms-source.tar.gz"
                exit 1
            fi
        fi
        ;;
    dms-greeter)
        info "Downloading source for dms-greeter..."
        if [ ! -f "dms-greeter-source.tar.gz" ]; then
            info "Downloading dms-greeter source..."
            if wget -O dms-greeter-source.tar.gz "https://github.com/AvengeMedia/DankMaterialShell/archive/refs/tags/v${VERSION}.tar.gz"; then
                success "source tarball downloaded"
            else
                error "Failed to download dms-greeter-source.tar.gz"
                exit 1
            fi
        fi
        ;;
    esac
fi

# Handle git packages
if [ "$IS_GIT_PACKAGE" = true ] && [ -n "$GIT_REPO" ]; then
    info "Detected git package: $PACKAGE_NAME"

    if [ -z "$SOURCE_DIR" ]; then
        BASE_NAME=$(echo "$PACKAGE_NAME" | sed 's/-git$//')
        if [ -d "${BASE_NAME}-source" ] 2>/dev/null; then
            SOURCE_DIR="${BASE_NAME}-source"
        elif [ -d "${BASE_NAME}-repo" ] 2>/dev/null; then
            SOURCE_DIR="${BASE_NAME}-repo"
        elif [ -d "$BASE_NAME" ] 2>/dev/null; then
            SOURCE_DIR="$BASE_NAME"
        else
            SOURCE_DIR="${BASE_NAME}-source"
        fi
    fi

    info "Cloning $GIT_REPO from GitHub (getting latest commit info)..."
    TEMP_CLONE=$(mktemp -d "$TEMP_BASE/ppa_clone_XXXXXX")
    if git clone "https://github.com/$GIT_REPO.git" "$TEMP_CLONE"; then
        GIT_COMMIT_HASH=$(cd "$TEMP_CLONE" && git rev-parse --short HEAD)
        GIT_COMMIT_COUNT=$(cd "$TEMP_CLONE" && git rev-list --count HEAD)
        UPSTREAM_VERSION=$(cd "$TEMP_CLONE" && git tag -l "v*" | sed 's/^v//' | sort -V | tail -1)
        if [ -z "$UPSTREAM_VERSION" ]; then
            UPSTREAM_VERSION=$(cd "$TEMP_CLONE" && git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)
        fi
        if [ -z "$UPSTREAM_VERSION" ]; then
            UPSTREAM_VERSION=$(cd "$TEMP_CLONE" && git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.1")
        fi
        if [ -z "$GIT_COMMIT_COUNT" ] || [ "$GIT_COMMIT_COUNT" = "0" ]; then
            error "Failed to get commit count from $GIT_REPO"
            rm -rf "$TEMP_CLONE"
            exit 1
        fi

        if [ -z "$GIT_COMMIT_HASH" ]; then
            error "Failed to get commit hash from $GIT_REPO"
            rm -rf "$TEMP_CLONE"
            exit 1
        fi

        success "Got commit info: $GIT_COMMIT_COUNT ($GIT_COMMIT_HASH), upstream: $UPSTREAM_VERSION"

        info "Updating changelog with git commit info..."
        BASE_VERSION="${UPSTREAM_VERSION}+git${GIT_COMMIT_COUNT}.${GIT_COMMIT_HASH}"
        CURRENT_VERSION=$(dpkg-parsechangelog -S Version 2>/dev/null || echo "")

        if [[ -n "${REBUILD_RELEASE:-}" ]]; then
            PPA_NUM=$REBUILD_RELEASE
            info "Using REBUILD_RELEASE=$REBUILD_RELEASE for PPA number"
        else
            PPA_NUM=1
            ESCAPED_BASE=$(echo "$BASE_VERSION" | sed 's/\./\\./g' | sed 's/+/\\+/g')
            if [[ "$CURRENT_VERSION" =~ ^${ESCAPED_BASE}ppa([0-9]+)$ ]]; then
                if [[ "$IS_MANUAL" == true ]] && [[ -z "${GITHUB_ACTIONS:-}" ]] && [[ -z "${CI:-}" ]]; then
                    # Only error for true local manual runs, not CI/workflow runs
                    error "Same commit detected ($CURRENT_VERSION) but no rebuild number specified"
                    error "To rebuild, explicitly specify a rebuild number:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME 2"
                    error "or use flag syntax:"
                    error "  ./distro/scripts/ppa-upload.sh $PACKAGE_NAME --rebuild=2"
                    exit 1
                else
                    info "Detected rebuild of same commit (current: $CURRENT_VERSION). No changes needed, skipping."
                    success "No changes needed (commit matches)."
                    exit 0
                fi
            else
                info "New commit or first build, using PPA number $PPA_NUM"
            fi
        fi

        NEW_VERSION="${BASE_VERSION}ppa${PPA_NUM}"

        # Single changelog entry (git snapshots don't need history)
        cat >debian/changelog <<EOF
${SOURCE_NAME} (${NEW_VERSION}) ${UBUNTU_SERIES}; urgency=medium

  * Git snapshot (commit ${GIT_COMMIT_COUNT}: ${GIT_COMMIT_HASH})

 -- Avenge Media <AvengeMedia.US@gmail.com>  $(date -R)
EOF
        success "Version updated to $NEW_VERSION"
        CHANGELOG_VERSION=$(dpkg-parsechangelog -S Version)

        info "Writing updated changelog back to repository..."
        cp debian/changelog "$PACKAGE_DIR/debian/changelog"
        success "Changelog written back to $PACKAGE_DIR/debian/changelog"

        rm -rf "$SOURCE_DIR"
        cp -r "$TEMP_CLONE" "$SOURCE_DIR"

        if [ "$PACKAGE_NAME" = "dms-git" ]; then
            info "Saving version info to .dms-version for build process..."
            echo "VERSION=${UPSTREAM_VERSION}+git${GIT_COMMIT_COUNT}.${GIT_COMMIT_HASH}" >"$SOURCE_DIR/.dms-version"
            echo "COMMIT=${GIT_COMMIT_HASH}" >>"$SOURCE_DIR/.dms-version"
            success "Version info saved: ${UPSTREAM_VERSION}+git${GIT_COMMIT_COUNT}.${GIT_COMMIT_HASH}"

            info "Vendoring Go dependencies for offline build..."
            cd "$SOURCE_DIR/core"
            go mod vendor

            if [ ! -d "vendor" ]; then
                error "Failed to vendor Go dependencies"
                exit 1
            fi

            success "Go dependencies vendored successfully"
            cd "$PACKAGE_DIR"
        fi

        rm -rf "$SOURCE_DIR/.git"
        rm -rf "$TEMP_CLONE"

        success "Source prepared for packaging"
    else
        error "Failed to clone $GIT_REPO"
        rm -rf "$TEMP_CLONE"
        exit 1
    fi
fi

# Handle packages that need pre-built binaries downloaded
cd "$WORK_PACKAGE_DIR"
case "$PACKAGE_NAME" in
danksearch)
    info "Downloading pre-built binaries for danksearch..."
    VERSION=$(dpkg-parsechangelog -S Version | sed 's/-[^-]*$//' | sed 's/ppa[0-9]*$//')

    if [ ! -f "dsearch-amd64" ]; then
        info "Downloading dsearch binary for amd64..."
        if wget -O dsearch-amd64.gz "https://github.com/AvengeMedia/danksearch/releases/download/v${VERSION}/dsearch-linux-amd64.gz"; then
            gunzip dsearch-amd64.gz
            chmod +x dsearch-amd64
            success "amd64 binary downloaded"
        else
            error "Failed to download dsearch-amd64.gz"
            exit 1
        fi
    fi

    if [ ! -f "dsearch-arm64" ]; then
        info "Downloading dsearch binary for arm64..."
        if wget -O dsearch-arm64.gz "https://github.com/AvengeMedia/danksearch/releases/download/v${VERSION}/dsearch-linux-arm64.gz"; then
            gunzip dsearch-arm64.gz
            chmod +x dsearch-arm64
            success "arm64 binary downloaded"
        else
            error "Failed to download dsearch-arm64.gz"
            exit 1
        fi
    fi
    ;;
dgop)
    if [ ! -f "dgop" ]; then
        warn "dgop binary not found - should be committed to repo"
    fi
    ;;
esac

cd "$WORK_PACKAGE_DIR"

if command -v rmadison >/dev/null 2>&1; then
    info "Checking if version already exists on PPA..."
    PPA_VERSION_CHECK=$(rmadison -u ppa:avengemedia/dms "$PACKAGE_NAME" 2>/dev/null | grep "$VERSION" || true)
    if [ -n "$PPA_VERSION_CHECK" ]; then
        warn "Version $VERSION already exists on PPA:"
        echo "$PPA_VERSION_CHECK"
        echo
        warn "Skipping upload to avoid duplicate. If this is a rebuild, increment the ppa number."
        cd "$PACKAGE_DIR"
        case "$PACKAGE_NAME" in
        dms-git)
            rm -rf DankMaterialShell-*
            success "Cleaned up DankMaterialShell-*/ directory"
            ;;
        esac
        exit 0
    fi
fi

info "Building source package..."
echo

SOURCE_FORMAT=$(head -1 "$WORK_PACKAGE_DIR/debian/source/format" 2>/dev/null || echo "3.0 (quilt)")

# Native format packages don't use orig tarballs - they include everything in one tarball
if [[ "$SOURCE_FORMAT" == *"native"* ]]; then
    info "Native format detected - including all source files (no orig tarball needed)"
    DEBUILD_SOURCE_FLAG="-sa"
elif [ -f "$PACKAGE_PARENT/${PACKAGE_NAME}_${VERSION%.ppa*}.orig.tar.xz" ]; then
    ORIG_TARBALL="${PACKAGE_NAME}_${VERSION%.ppa*}.orig.tar.xz"
    info "Found existing orig tarball in $PACKAGE_PARENT, using -sd (debian changes only)"
    cp "$PACKAGE_PARENT/$ORIG_TARBALL" "$TEMP_WORK_DIR/"
    DEBUILD_SOURCE_FLAG="-sd"
else
    info "No existing orig tarball found, using -sa (include original source)"
    DEBUILD_SOURCE_FLAG="-sa"
fi

# -d skips dependency checking (we're building on Fedora, not Ubuntu)
if yes | DEBIAN_FRONTEND=noninteractive debuild -S $DEBUILD_SOURCE_FLAG -d; then
    echo
    success "Source package built successfully!"

    TEMP_MARKER_FILE="$PACKAGE_PARENT/.ppa_build_temp_${PACKAGE_NAME}"
    echo "PPA_BUILD_TEMP_DIR=$TEMP_WORK_DIR" > "$TEMP_MARKER_FILE"

    if [[ -z "${PPA_UPLOAD_SCRIPT:-}" ]] && ! pgrep -f "ppa-upload.sh" >/dev/null 2>&1; then
        info "Copying build artifacts to $PACKAGE_PARENT (standalone build)..."
        cp -v "$TEMP_WORK_DIR"/"${SOURCE_NAME}"_"${CHANGELOG_VERSION}"* "$PACKAGE_PARENT/" 2>/dev/null || true
        info "Generated files in $PACKAGE_PARENT:"
        ls -lh "$PACKAGE_PARENT"/"${SOURCE_NAME}"_"${CHANGELOG_VERSION}"* 2>/dev/null || true
    fi

    # Show what to do next
    echo
    info "Next steps:"
    echo "  1. Review the source package:"
    echo "     cd $PACKAGE_PARENT"
    echo "     ls -lh ${SOURCE_NAME}_${CHANGELOG_VERSION}*"
    echo
    echo "  2. Upload to PPA (stable):"
    echo "     dput ppa:avengemedia/dms ${SOURCE_NAME}_${CHANGELOG_VERSION}_source.changes"
    echo
    echo "  3. Or upload to PPA (nightly):"
    echo "     dput ppa:avengemedia/dms-git ${SOURCE_NAME}_${CHANGELOG_VERSION}_source.changes"
    echo
    echo "  4. Or use the upload script:"
    echo "     ./upload-ppa.sh $PACKAGE_PARENT/${SOURCE_NAME}_${CHANGELOG_VERSION}_source.changes dms"

else
    error "Source package build failed!"
    exit 1
fi
