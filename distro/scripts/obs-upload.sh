#!/bin/bash
# Unified OBS upload script for dms packages
# Handles Debian and OpenSUSE builds for both x86_64 and aarch64
# Usage: ./distro/scripts/obs-upload.sh [distro] <package-name> [commit-message]
#
# Examples:
#   ./distro/scripts/obs-upload.sh dms "Update to v0.6.2"
#   ./distro/scripts/obs-upload.sh debian dms
#   ./distro/scripts/obs-upload.sh opensuse dms-git

set -e

UPLOAD_DEBIAN=true
UPLOAD_OPENSUSE=true
PACKAGE=""
MESSAGE=""

for arg in "$@"; do
    case "$arg" in
        debian)
            UPLOAD_DEBIAN=true
            UPLOAD_OPENSUSE=false
            ;;
        opensuse)
            UPLOAD_DEBIAN=false
            UPLOAD_OPENSUSE=true
            ;;
        *)
            if [[ -z "$PACKAGE" ]]; then
                PACKAGE="$arg"
            elif [[ -z "$MESSAGE" ]]; then
                MESSAGE="$arg"
            fi
            ;;
    esac
done

OBS_BASE_PROJECT="home:AvengeMedia"
OBS_BASE="$HOME/.cache/osc-checkouts"

# Available packages
AVAILABLE_PACKAGES=(dms dms-git)

if [[ -z "$PACKAGE" ]]; then
    echo "Available packages:"
    echo ""
    echo "  1. dms         - Stable DMS"
    echo "  2. dms-git     - Nightly DMS"
    echo "  a. all"
    echo ""
    read -p "Select package (1-${#AVAILABLE_PACKAGES[@]}, a): " selection
    
    if [[ "$selection" == "a" ]] || [[ "$selection" == "all" ]]; then
        PACKAGE="all"
    elif [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#AVAILABLE_PACKAGES[@]} ]]; then
        PACKAGE="${AVAILABLE_PACKAGES[$((selection-1))]}"
    else
        echo "Error: Invalid selection"
        exit 1
    fi
    
fi

if [[ -z "$MESSAGE" ]]; then
    MESSAGE="Update packaging"
fi

# Get repo root (2 levels up from distro/scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

# Ensure we're in repo root
if [[ ! -d "distro/debian" ]]; then
    echo "Error: Run this script from the repository root"
    exit 1
fi

# Handle "all" option
if [[ "$PACKAGE" == "all" ]]; then
    echo "==> Uploading all packages"
    DISTRO_ARG=""
    if [[ "$UPLOAD_DEBIAN" == true && "$UPLOAD_OPENSUSE" == false ]]; then
        DISTRO_ARG="debian"
    elif [[ "$UPLOAD_DEBIAN" == false && "$UPLOAD_OPENSUSE" == true ]]; then
        DISTRO_ARG="opensuse"
    fi
    echo ""
    FAILED=()
    for pkg in "${AVAILABLE_PACKAGES[@]}"; do
        if [[ -d "distro/debian/$pkg" ]]; then
            echo "=========================================="
            echo "Uploading $pkg..."
            echo "=========================================="
            if [[ -n "$DISTRO_ARG" ]]; then
                if bash "$0" "$DISTRO_ARG" "$pkg" "$MESSAGE"; then
                    echo "✅ $pkg uploaded successfully"
                else
                    echo "❌ $pkg failed to upload"
                    FAILED+=("$pkg")
                fi
            else
                if bash "$0" "$pkg" "$MESSAGE"; then
                    echo "✅ $pkg uploaded successfully"
                else
                    echo "❌ $pkg failed to upload"
                    FAILED+=("$pkg")
                fi
            fi
            echo ""
        else
            echo "⚠️  Skipping $pkg (not found in distro/debian/)"
        fi
    done
    
    if [[ ${#FAILED[@]} -eq 0 ]]; then
        echo "✅ All packages uploaded successfully!"
        exit 0
    else
        echo "❌ Some packages failed: ${FAILED[*]}"
        exit 1
    fi
fi

# Check if package exists
if [[ ! -d "distro/debian/$PACKAGE" ]]; then
    echo "Error: Package '$PACKAGE' not found in distro/debian/"
    exit 1
fi

case "$PACKAGE" in
    dms)
        PROJECT="dms"
        ;;
    dms-git)
        PROJECT="dms-git"
        ;;
    *)
        echo "Error: Unknown package '$PACKAGE'"
        exit 1
        ;;
esac

OBS_PROJECT="${OBS_BASE_PROJECT}:${PROJECT}"

echo "==> Target: $OBS_PROJECT / $PACKAGE"
echo "==> Message: $MESSAGE"
if [[ "$UPLOAD_DEBIAN" == true && "$UPLOAD_OPENSUSE" == true ]]; then
    echo "==> Distributions: Debian + OpenSUSE"
elif [[ "$UPLOAD_DEBIAN" == true ]]; then
    echo "==> Distribution: Debian only"
elif [[ "$UPLOAD_OPENSUSE" == true ]]; then
    echo "==> Distribution: OpenSUSE only"
fi

# Create .obs directory if it doesn't exist
mkdir -p "$OBS_BASE"

# Check out package if not already present
if [[ ! -d "$OBS_BASE/$OBS_PROJECT/$PACKAGE" ]]; then
    echo "Checking out $OBS_PROJECT/$PACKAGE..."
    cd "$OBS_BASE"
    osc co "$OBS_PROJECT/$PACKAGE"
    cd "$REPO_ROOT"
fi

WORK_DIR="$OBS_BASE/$OBS_PROJECT/$PACKAGE"

echo "==> Preparing $PACKAGE for OBS upload"

# Clean working directory (keep osc metadata)
find "$WORK_DIR" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.spec" -o -name "_service" -o -name "*.dsc" \) -delete 2>/dev/null || true

if [[ -f "distro/debian/$PACKAGE/_service" ]]; then
    echo "  - Copying _service (for binary downloads)"
    cp "distro/debian/$PACKAGE/_service" "$WORK_DIR/"
fi

# Copy OpenSUSE spec if it exists and handle auto-increment
if [[ "$UPLOAD_OPENSUSE" == true ]] && [[ -f "distro/opensuse/$PACKAGE.spec" ]]; then
    echo "  - Copying $PACKAGE.spec for OpenSUSE"
    cp "distro/opensuse/$PACKAGE.spec" "$WORK_DIR/"

    # Auto-increment Release if same Version is being rebuilt
    if [[ -f "$WORK_DIR/.osc/$PACKAGE.spec" ]]; then
        NEW_VERSION=$(grep "^Version:" "$WORK_DIR/$PACKAGE.spec" | awk '{print $2}' | head -1)
        NEW_RELEASE=$(grep "^Release:" "$WORK_DIR/$PACKAGE.spec" | sed 's/^Release:[[:space:]]*//' | sed 's/%{?dist}//' | head -1)

        OLD_VERSION=$(grep "^Version:" "$WORK_DIR/.osc/$PACKAGE.spec" | awk '{print $2}' | head -1)
        OLD_RELEASE=$(grep "^Release:" "$WORK_DIR/.osc/$PACKAGE.spec" | sed 's/^Release:[[:space:]]*//' | sed 's/%{?dist}//' | head -1)

        if [[ "$NEW_VERSION" == "$OLD_VERSION" ]]; then
            # Same version - increment release number
            if [[ "$OLD_RELEASE" =~ ^([0-9]+) ]]; then
                BASE_RELEASE="${BASH_REMATCH[1]}"
                NEXT_RELEASE=$((BASE_RELEASE + 1))
                echo "  - Detected rebuild of same version $NEW_VERSION (release $OLD_RELEASE -> $NEXT_RELEASE)"
                sed -i "s/^Release:[[:space:]]*${NEW_RELEASE}%{?dist}/Release:        ${NEXT_RELEASE}%{?dist}/" "$WORK_DIR/$PACKAGE.spec"
            fi
        else
            echo "  - New version detected: $OLD_VERSION -> $NEW_VERSION (keeping release $NEW_RELEASE)"
        fi
    else
        echo "  - First upload to OBS (no previous spec found)"
    fi
elif [[ "$UPLOAD_OPENSUSE" == true ]]; then
    echo "  - Warning: OpenSUSE spec file not found, skipping OpenSUSE upload"
fi

# Handle OpenSUSE-only uploads (create tarball without Debian processing)
if [[ "$UPLOAD_OPENSUSE" == true ]] && [[ "$UPLOAD_DEBIAN" == false ]] && [[ -f "distro/opensuse/$PACKAGE.spec" ]]; then
    echo "  - OpenSUSE-only upload: creating source tarball"

    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Check _service file to determine how to get source
    if [[ -f "distro/debian/$PACKAGE/_service" ]]; then
        # Check for tar_scm (git source)
        if grep -q "tar_scm" "distro/debian/$PACKAGE/_service"; then
            GIT_URL=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "url" | sed 's/.*<param name="url">\(.*\)<\/param>.*/\1/')
            GIT_REVISION=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "revision" | sed 's/.*<param name="revision">\(.*\)<\/param>.*/\1/')

            if [[ -n "$GIT_URL" ]]; then
                echo "    Cloning git source from: $GIT_URL (revision: ${GIT_REVISION:-master})"
                SOURCE_DIR="$TEMP_DIR/dms-git-source"
                if git clone --depth 1 --branch "${GIT_REVISION:-master}" "$GIT_URL" "$SOURCE_DIR" 2>/dev/null || \
                   git clone --depth 1 "$GIT_URL" "$SOURCE_DIR" 2>/dev/null; then
                    cd "$SOURCE_DIR"
                    if [[ -n "$GIT_REVISION" ]]; then
                        git checkout "$GIT_REVISION" 2>/dev/null || true
                    fi
                    SOURCE_DIR=$(pwd)
                    cd "$REPO_ROOT"
                fi
            fi
        fi
    fi

    if [[ -n "$SOURCE_DIR" && -d "$SOURCE_DIR" ]]; then
        # Extract Source0 from spec file
        SOURCE0=$(grep "^Source0:" "distro/opensuse/$PACKAGE.spec" | awk '{print $2}' | head -1)

        if [[ -n "$SOURCE0" ]]; then
            OBS_TARBALL_DIR=$(mktemp -d -t obs-tarball-XXXXXX)
            cd "$OBS_TARBALL_DIR"

            case "$PACKAGE" in
                dms)
                    DMS_VERSION=$(grep "^Version:" "$REPO_ROOT/distro/opensuse/$PACKAGE.spec" | sed 's/^Version:[[:space:]]*//' | head -1)
                    EXPECTED_DIR="DankMaterialShell-${DMS_VERSION}"
                    ;;
                dms-git)
                    EXPECTED_DIR="dms-git-source"
                    ;;
                *)
                    EXPECTED_DIR=$(basename "$SOURCE_DIR")
                    ;;
            esac

            echo "    Creating $SOURCE0 (directory: $EXPECTED_DIR)"
            cp -r "$SOURCE_DIR" "$EXPECTED_DIR"
            tar -czf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
            rm -rf "$EXPECTED_DIR"
            echo "    Created $SOURCE0 ($(stat -c%s "$WORK_DIR/$SOURCE0" 2>/dev/null || echo 0) bytes)"

            cd "$REPO_ROOT"
            rm -rf "$OBS_TARBALL_DIR"
        fi
    else
        echo "  - Warning: Could not obtain source for OpenSUSE tarball"
    fi
fi

# Generate .dsc file and handle source format (for Debian only)
if [[ "$UPLOAD_DEBIAN" == true ]] && [[ -d "distro/debian/$PACKAGE/debian" ]]; then
    # Get version from changelog
    CHANGELOG_VERSION=$(grep -m1 "^$PACKAGE" distro/debian/$PACKAGE/debian/changelog 2>/dev/null | sed 's/.*(\([^)]*\)).*/\1/' || echo "0.1.11")
    
    # Determine source format
    SOURCE_FORMAT=$(cat "distro/debian/$PACKAGE/debian/source/format" 2>/dev/null || echo "3.0 (quilt)")
    
    # Handle native format (3.0 native)
    if [[ "$SOURCE_FORMAT" == *"native"* ]]; then
        echo "  - Native format detected: creating combined tarball"

        VERSION="$CHANGELOG_VERSION"
        
        # Create temp directory for building combined tarball
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT
        
        # Determine tarball name for native format (use version without revision)
        COMBINED_TARBALL="${PACKAGE}_${VERSION}.tar.gz"
        
        SOURCE_DIR=""
        
        # Check _service file to determine how to get source
        if [[ -f "distro/debian/$PACKAGE/_service" ]]; then
            # Check for tar_scm first (git source) - this takes priority for git packages
            if grep -q "tar_scm" "distro/debian/$PACKAGE/_service"; then
                # For dms-git, use tar_scm to get git source
                GIT_URL=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "url" | sed 's/.*<param name="url">\(.*\)<\/param>.*/\1/')
                GIT_REVISION=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "revision" | sed 's/.*<param name="revision">\(.*\)<\/param>.*/\1/')
                
                if [[ -n "$GIT_URL" ]]; then
                    echo "    Cloning git source from: $GIT_URL (revision: ${GIT_REVISION:-master})"
                    SOURCE_DIR="$TEMP_DIR/dms-git-source"
                    if git clone --depth 1 --branch "${GIT_REVISION:-master}" "$GIT_URL" "$SOURCE_DIR" 2>/dev/null || \
                       git clone --depth 1 "$GIT_URL" "$SOURCE_DIR" 2>/dev/null; then
                        cd "$SOURCE_DIR"
                        if [[ -n "$GIT_REVISION" ]]; then
                            git checkout "$GIT_REVISION" 2>/dev/null || true
                        fi
                        SOURCE_DIR=$(pwd)
                        cd "$REPO_ROOT"
                    else
                        echo "Error: Failed to clone git repository"
                        exit 1
                    fi
                fi
            elif grep -q "download_url" "distro/debian/$PACKAGE/_service" && [[ "$PACKAGE" != "dms-git" ]]; then
                # Extract download_url for source (skip binary downloads)
                # Look for download_url with "source" in path or .tar.gz/.tar.xz archives
                # Skip binaries (distropkg, standalone .gz files, etc.)
                
                # Extract all paths from download_url services
                ALL_PATHS=$(grep -A 5 '<service name="download_url">' "distro/debian/$PACKAGE/_service" | \
                    grep '<param name="path">' | \
                    sed 's/.*<param name="path">\(.*\)<\/param>.*/\1/')
                
                # Find source path (has "source" or ends with .tar.gz/.tar.xz, but not distropkg)
                SOURCE_PATH=""
                for path in $ALL_PATHS; do
                    if echo "$path" | grep -qE "(source|archive|\.tar\.(gz|xz|bz2))" && \
                       ! echo "$path" | grep -qE "(distropkg|binary)"; then
                        SOURCE_PATH="$path"
                        break
                    fi
                done
                
                # If no source found, try first path that ends with .tar.gz/.tar.xz
                if [[ -z "$SOURCE_PATH" ]]; then
                    for path in $ALL_PATHS; do
                        if echo "$path" | grep -qE "\.tar\.(gz|xz|bz2)$"; then
                            SOURCE_PATH="$path"
                            break
                        fi
                    done
                fi
                
                if [[ -n "$SOURCE_PATH" ]]; then
                    # Extract the service block containing this path
                    SOURCE_BLOCK=$(awk -v target="$SOURCE_PATH" '
                        /<service name="download_url">/ { in_block=1; block="" }
                        in_block { block=block"\n"$0 }
                        /<\/service>/ { 
                            if (in_block && block ~ target) {
                                print block
                                exit
                            }
                            in_block=0
                        }
                    ' "distro/debian/$PACKAGE/_service")
                    
                    URL_PROTOCOL=$(echo "$SOURCE_BLOCK" | grep "protocol" | sed 's/.*<param name="protocol">\(.*\)<\/param>.*/\1/' | head -1)
                    URL_HOST=$(echo "$SOURCE_BLOCK" | grep "host" | sed 's/.*<param name="host">\(.*\)<\/param>.*/\1/' | head -1)
                    URL_PATH="$SOURCE_PATH"
                fi
                
                if [[ -n "$URL_PROTOCOL" && -n "$URL_HOST" && -n "$URL_PATH" ]]; then
                    SOURCE_URL="${URL_PROTOCOL}://${URL_HOST}${URL_PATH}"
                    echo "    Downloading source from: $SOURCE_URL"
                    
                    if wget -q -O "$TEMP_DIR/source-archive" "$SOURCE_URL"; then
                        cd "$TEMP_DIR"
                        if [[ "$SOURCE_URL" == *.tar.xz ]]; then
                            tar -xJf source-archive
                        elif [[ "$SOURCE_URL" == *.tar.gz ]] || [[ "$SOURCE_URL" == *.tgz ]]; then
                            tar -xzf source-archive
                        fi
                        # GitHub archives extract to DankMaterialShell-VERSION/ or similar
                        SOURCE_DIR=$(find . -maxdepth 1 -type d -name "DankMaterialShell-*" | head -1)
                        if [[ -z "$SOURCE_DIR" ]]; then
                            # Try to find any extracted directory
                            SOURCE_DIR=$(find . -maxdepth 1 -type d ! -name "." | head -1)
                        fi
                        if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
                            echo "Error: Failed to extract source archive or find source directory"
                            echo "Contents of $TEMP_DIR:"
                            ls -la "$TEMP_DIR"
                            cd "$REPO_ROOT"
                            exit 1
                        fi
                        # Convert to absolute path
                        SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)
                        cd "$REPO_ROOT"
                    else
                        echo "Error: Failed to download source from $SOURCE_URL"
                        exit 1
                    fi
                fi
            fi
        fi
        
        if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
            echo "Error: Could not determine or obtain source for $PACKAGE"
            echo "SOURCE_DIR: $SOURCE_DIR"
            if [[ -d "$TEMP_DIR" ]]; then
                echo "Contents of temp directory:"
                ls -la "$TEMP_DIR"
            fi
            exit 1
        fi
        
        echo "    Found source directory: $SOURCE_DIR"
        
        # Create OpenSUSE-compatible source tarballs BEFORE adding debian/ directory
        # (OpenSUSE doesn't need debian/ directory)
        if [[ "$UPLOAD_OPENSUSE" == true ]] && [[ -f "distro/opensuse/$PACKAGE.spec" ]]; then
            # If SOURCE_DIR is not set (OpenSUSE-only upload), detect source now
            if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
                echo "  - Detecting source for OpenSUSE-only upload"
                if [[ -z "$TEMP_DIR" ]]; then
                    TEMP_DIR=$(mktemp -d)
                    trap "rm -rf $TEMP_DIR" EXIT
                fi
                
                # Check _service file to determine how to get source
                if [[ -f "distro/debian/$PACKAGE/_service" ]]; then
                    # Check for tar_scm first (git source) - this takes priority for git packages
                    if grep -q "tar_scm" "distro/debian/$PACKAGE/_service"; then
                        # For dms-git, use tar_scm to get git source
                        GIT_URL=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "url" | sed 's/.*<param name="url">\(.*\)<\/param>.*/\1/')
                        GIT_REVISION=$(grep -A 5 'name="tar_scm"' "distro/debian/$PACKAGE/_service" | grep "revision" | sed 's/.*<param name="revision">\(.*\)<\/param>.*/\1/')
                        
                        if [[ -n "$GIT_URL" ]]; then
                            echo "    Cloning git source from: $GIT_URL (revision: ${GIT_REVISION:-master})"
                            SOURCE_DIR="$TEMP_DIR/dms-git-source"
                            if git clone --depth 1 --branch "${GIT_REVISION:-master}" "$GIT_URL" "$SOURCE_DIR" 2>/dev/null || \
                               git clone --depth 1 "$GIT_URL" "$SOURCE_DIR" 2>/dev/null; then
                                cd "$SOURCE_DIR"
                                if [[ -n "$GIT_REVISION" ]]; then
                                    git checkout "$GIT_REVISION" 2>/dev/null || true
                                fi
                                SOURCE_DIR=$(pwd)
                                cd "$REPO_ROOT"
                            else
                                echo "Error: Failed to clone git repository"
                                exit 1
                            fi
                        fi
                    elif grep -q "download_url" "distro/debian/$PACKAGE/_service" && [[ "$PACKAGE" != "dms-git" ]]; then
                        # Extract download_url for source (skip binary downloads)
                        ALL_PATHS=$(grep -A 5 '<service name="download_url">' "distro/debian/$PACKAGE/_service" | \
                            grep '<param name="path">' | \
                            sed 's/.*<param name="path">\(.*\)<\/param>.*/\1/')
                        
                        # Find source path (has "source" or ends with .tar.gz/.tar.xz, but not distropkg)
                        SOURCE_PATH=""
                        for path in $ALL_PATHS; do
                            if echo "$path" | grep -qE "(source|archive|\.tar\.(gz|xz|bz2))" && \
                               ! echo "$path" | grep -qE "(distropkg|binary)"; then
                                SOURCE_PATH="$path"
                                break
                            fi
                        done
                        
                        # If no source found, try first path that ends with .tar.gz/.tar.xz
                        if [[ -z "$SOURCE_PATH" ]]; then
                            for path in $ALL_PATHS; do
                                if echo "$path" | grep -qE "\.tar\.(gz|xz|bz2)$"; then
                                    SOURCE_PATH="$path"
                                    break
                                fi
                            done
                        fi
                        
                        if [[ -n "$SOURCE_PATH" ]]; then
                            # Extract the service block containing this path
                            SOURCE_BLOCK=$(awk -v target="$SOURCE_PATH" '
                                /<service name="download_url">/ { in_block=1; block="" }
                                in_block { block=block"\n"$0 }
                                /<\/service>/ { 
                                    if (in_block && block ~ target) {
                                        print block
                                        exit
                                    }
                                    in_block=0
                                }
                            ' "distro/debian/$PACKAGE/_service")
                            
                            URL_PROTOCOL=$(echo "$SOURCE_BLOCK" | grep "protocol" | sed 's/.*<param name="protocol">\(.*\)<\/param>.*/\1/' | head -1)
                            URL_HOST=$(echo "$SOURCE_BLOCK" | grep "host" | sed 's/.*<param name="host">\(.*\)<\/param>.*/\1/' | head -1)
                            URL_PATH="$SOURCE_PATH"
                        fi
                        
                        if [[ -n "$URL_PROTOCOL" && -n "$URL_HOST" && -n "$URL_PATH" ]]; then
                            SOURCE_URL="${URL_PROTOCOL}://${URL_HOST}${URL_PATH}"
                            echo "    Downloading source from: $SOURCE_URL"
                            
                            if wget -q -O "$TEMP_DIR/source-archive" "$SOURCE_URL"; then
                                cd "$TEMP_DIR"
                                if [[ "$SOURCE_URL" == *.tar.xz ]]; then
                                    tar -xJf source-archive
                                elif [[ "$SOURCE_URL" == *.tar.gz ]] || [[ "$SOURCE_URL" == *.tgz ]]; then
                                    tar -xzf source-archive
                                fi
                                # GitHub archives extract to DankMaterialShell-VERSION/ or similar
                                SOURCE_DIR=$(find . -maxdepth 1 -type d -name "DankMaterialShell-*" | head -1)
                                if [[ -z "$SOURCE_DIR" ]]; then
                                    # Try to find any extracted directory
                                    SOURCE_DIR=$(find . -maxdepth 1 -type d ! -name "." | head -1)
                                fi
                                if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
                                    echo "Error: Failed to extract source archive or find source directory"
                                    echo "Contents of $TEMP_DIR:"
                                    ls -la "$TEMP_DIR"
                                    cd "$REPO_ROOT"
                                    exit 1
                                fi
                                # Convert to absolute path
                                SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)
                                cd "$REPO_ROOT"
                            else
                                echo "Error: Failed to download source from $SOURCE_URL"
                                exit 1
                            fi
                        fi
                    fi
                fi
                
                if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
                    echo "Error: Could not determine or obtain source for $PACKAGE (OpenSUSE-only upload)"
                    echo "SOURCE_DIR: $SOURCE_DIR"
                    if [[ -d "$TEMP_DIR" ]]; then
                        echo "Contents of temp directory:"
                        ls -la "$TEMP_DIR"
                    fi
                    exit 1
                fi
                
                echo "    Found source directory: $SOURCE_DIR"
            fi
            echo "  - Creating OpenSUSE-compatible source tarballs"
            
            # Extract Source0 from spec file
            SOURCE0=$(grep "^Source0:" "distro/opensuse/$PACKAGE.spec" | awk '{print $2}' | head -1); if [[ -z "$SOURCE0" && "$PACKAGE" == "dms-git" ]]; then SOURCE0="dms-git-source.tar.gz"; fi

            if [[ -n "$SOURCE0" ]]; then
                # Create a separate temporary directory for OpenSUSE tarball creation to avoid conflicts
                OBS_TARBALL_DIR=$(mktemp -d -t obs-tarball-XXXXXX)
                cd "$OBS_TARBALL_DIR"
                
                case "$PACKAGE" in
                    dms)
                        # dms spec expects DankMaterialShell-%{version} directory (from %setup -q -n DankMaterialShell-%{version})
                        # Extract version from spec file
                        DMS_VERSION=$(grep "^Version:" "$REPO_ROOT/distro/opensuse/$PACKAGE.spec" | sed 's/^Version:[[:space:]]*//' | head -1)
                        EXPECTED_DIR="DankMaterialShell-${DMS_VERSION}"
                        echo "    Creating $SOURCE0 (directory: $EXPECTED_DIR)"
                        cp -r "$SOURCE_DIR" "$EXPECTED_DIR"
                        if [[ "$SOURCE0" == *.tar.xz ]]; then
                            tar -cJf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        elif [[ "$SOURCE0" == *.tar.bz2 ]]; then
                            tar -cjf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        else
                            tar -czf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        fi
                        rm -rf "$EXPECTED_DIR"
                        echo "    Created $SOURCE0 ($(stat -c%s "$WORK_DIR/$SOURCE0" 2>/dev/null || echo 0) bytes)"
                        ;;
                    dms-git)
                        # dms-git spec expects dms-git-source directory (from %setup -q -n dms-git-source)
                        EXPECTED_DIR="dms-git-source"
                        echo "    Creating $SOURCE0 (directory: $EXPECTED_DIR)"
                        cp -r "$SOURCE_DIR" "$EXPECTED_DIR"
                        if [[ "$SOURCE0" == *.tar.xz ]]; then
                            tar -cJf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        elif [[ "$SOURCE0" == *.tar.bz2 ]]; then
                            tar -cjf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        else
                            tar -czf "$WORK_DIR/$SOURCE0" "$EXPECTED_DIR"
                        fi
                        rm -rf "$EXPECTED_DIR"
                        echo "    Created $SOURCE0 ($(stat -c%s "$WORK_DIR/$SOURCE0" 2>/dev/null || echo 0) bytes)"
                        ;;
                    *)
                        # Generic handling
                        DIR_NAME=$(basename "$SOURCE_DIR")
                        echo "    Creating $SOURCE0 (directory: $DIR_NAME)"
                        cp -r "$SOURCE_DIR" "$DIR_NAME"
                        if [[ "$SOURCE0" == *.tar.xz ]]; then
                            tar -cJf "$WORK_DIR/$SOURCE0" "$DIR_NAME"
                        elif [[ "$SOURCE0" == *.tar.bz2 ]]; then
                            tar -cjf "$WORK_DIR/$SOURCE0" "$DIR_NAME"
                        else
                            tar -czf "$WORK_DIR/$SOURCE0" "$DIR_NAME"
                        fi
                        rm -rf "$DIR_NAME"
                        echo "    Created $SOURCE0 ($(stat -c%s "$WORK_DIR/$SOURCE0" 2>/dev/null || echo 0) bytes)"
                        ;;
                esac
                # Clean up the tarball work directory
                cd "$REPO_ROOT"
                rm -rf "$OBS_TARBALL_DIR"
                echo "  - OpenSUSE source tarballs created"
            fi
            
            # Copy spec file
            cp "distro/opensuse/$PACKAGE.spec" "$WORK_DIR/"
        fi
        
        # Copy debian/ directory into source (for Debian builds only)
        if [[ "$UPLOAD_DEBIAN" == true ]]; then
            echo "    Copying debian/ directory into source"
            cp -r "distro/debian/$PACKAGE/debian" "$SOURCE_DIR/"
            
            # Create combined tarball
            echo "    Creating combined tarball: $COMBINED_TARBALL"
            cd "$(dirname "$SOURCE_DIR")"
            TARBALL_BASE=$(basename "$SOURCE_DIR")
            tar -czf "$WORK_DIR/$COMBINED_TARBALL" "$TARBALL_BASE"
            cd "$REPO_ROOT"
            
            # Generate .dsc file for native format
            TARBALL_SIZE=$(stat -c%s "$WORK_DIR/$COMBINED_TARBALL" 2>/dev/null || stat -f%z "$WORK_DIR/$COMBINED_TARBALL" 2>/dev/null)
            TARBALL_MD5=$(md5sum "$WORK_DIR/$COMBINED_TARBALL" | cut -d' ' -f1)
            
            # Extract Build-Depends from control file
            BUILD_DEPS="debhelper-compat (= 13)"
            if [[ -f "distro/debian/$PACKAGE/debian/control" ]]; then
                CONTROL_DEPS=$(sed -n '/^Build-Depends:/,/^[A-Z]/p' "distro/debian/$PACKAGE/debian/control" | \
                    sed '/^Build-Depends:/s/^Build-Depends: *//' | \
                    sed '/^[A-Z]/d' | \
                    tr '\n' ' ' | \
                    sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]]\+/ /g')
                if [[ -n "$CONTROL_DEPS" && "$CONTROL_DEPS" != "" ]]; then
                    BUILD_DEPS="$CONTROL_DEPS"
                fi
            fi
            
            cat > "$WORK_DIR/$PACKAGE.dsc" << EOF
Format: 3.0 (native)
Source: $PACKAGE
Binary: $PACKAGE
Architecture: any
Version: $VERSION
Maintainer: Avenge Media <AvengeMedia.US@gmail.com>
Build-Depends: $BUILD_DEPS
Files:
 $TARBALL_MD5 $TARBALL_SIZE $COMBINED_TARBALL
EOF
            
            echo "  - Generated $PACKAGE.dsc for native format"
        fi
    else
        # Quilt format (legacy) - for Debian only
        if [[ "$UPLOAD_DEBIAN" == true ]]; then
            # For quilt format, version can have revision
            if [[ "$CHANGELOG_VERSION" == *"-"* ]]; then
                VERSION="$CHANGELOG_VERSION"
            else
                VERSION="${CHANGELOG_VERSION}-1"
            fi
            
            echo "  - Quilt format detected: creating debian.tar.gz"
            tar -czf "$WORK_DIR/debian.tar.gz" -C "distro/debian/$PACKAGE" debian/
            
            echo "  - Generating $PACKAGE.dsc for quilt format"
            cat > "$WORK_DIR/$PACKAGE.dsc" << EOF
Format: 3.0 (quilt)
Source: $PACKAGE
Binary: $PACKAGE
Architecture: any
Version: $VERSION
Maintainer: Avenge Media <AvengeMedia.US@gmail.com>
Build-Depends: debhelper-compat (= 13), wget, gzip
DEBTRANSFORM-TAR: debian.tar.gz
Files:
 00000000000000000000000000000000 1 debian.tar.gz
EOF
        fi
    fi
fi

# Change to working directory and commit
cd "$WORK_DIR"

echo "==> Staging changes"
# List files to be uploaded
echo "Files to upload:"
# Only list files relevant to the selected upload type
if [[ "$UPLOAD_DEBIAN" == true ]] && [[ "$UPLOAD_OPENSUSE" == true ]]; then
    ls -lh *.tar.gz *.tar.xz *.tar *.spec *.dsc _service 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
elif [[ "$UPLOAD_DEBIAN" == true ]]; then
    ls -lh *.tar.gz *.dsc _service 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
elif [[ "$UPLOAD_OPENSUSE" == true ]]; then
    ls -lh *.tar.gz *.tar.xz *.tar *.spec _service 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
fi
echo ""

osc addremove

echo "==> Committing to OBS"
osc commit -m "$MESSAGE"

echo "==> Checking build status"
osc results

echo ""
echo "Upload complete! Monitor builds with:"
echo "  cd $WORK_DIR && osc results"
echo "  cd $WORK_DIR && osc buildlog <repo> <arch>"
echo ""

# Don't cleanup - keep checkout for status checking
echo ""
echo "Upload complete! Build status:"
cd "$WORK_DIR"
osc results 2>&1 | head -10
cd "$REPO_ROOT"

echo ""
echo "To check detailed status:"
echo "  cd $WORK_DIR && osc results"
echo "  cd $WORK_DIR && osc remotebuildlog $OBS_PROJECT $PACKAGE Debian_13 x86_64"
echo ""
echo "NOTE: Checkout kept at $WORK_DIR for status checking"
echo ""
echo "✅ Upload complete!"
echo ""
echo "Check build status with:"
echo "  ./distro/scripts/obs-status.sh $PACKAGE"
