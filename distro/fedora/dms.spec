# Spec for DMS - uses rpkg macros for git builds

%global debug_package %{nil}
%global version {{{ git_repo_version }}}
%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors

Name:           dms
Epoch:          1
Version:        %{version}
Release:        1%{?dist}
Summary:        %{pkg_summary}

License:        MIT
URL:            https://github.com/AvengeMedia/DankMaterialShell
VCS:            {{{ git_repo_vcs }}}
Source0:        {{{ git_repo_pack }}}

BuildRequires:  git-core
BuildRequires:  rpkg
BuildRequires:  gzip
BuildRequires:  golang >= 1.24
BuildRequires:  make
BuildRequires:  wget
BuildRequires:  systemd-rpm-macros

# Core requirements
Requires:       (quickshell-git or quickshell)
Requires:       accountsservice
Requires:       dms-cli
Requires:       dgop

# Core utilities (Highly recommended for DMS functionality)
Recommends:     cava
Recommends:     cliphist
Recommends:     danksearch
Recommends:     hyprpicker
Recommends:     matugen
Recommends:     quickshell-git
Recommends:     wl-clipboard

# Recommended system packages
Recommends:     NetworkManager
Recommends:     qt6-qtmultimedia
Suggests:       qt6ct

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for the niri, hyprland, sway, and dwl (MangoWC) compositors. Features notifications,
app launcher, wallpaper customization, and fully customizable with plugins.

Includes auto-theming for GTK/Qt apps with matugen, 20+ customizable widgets,
process monitoring, notification center, clipboard history, dock, control center,
lock screen, and comprehensive plugin system.

%package -n dms-cli
Summary:        DankMaterialShell CLI tool
License:        MIT
URL:            https://github.com/AvengeMedia/DankMaterialShell

%description -n dms-cli
Command-line interface for DankMaterialShell configuration and management.
Provides native DBus bindings, NetworkManager integration, and system utilities.

%package -n dgop
Summary:        Stateless CPU/GPU monitor for DankMaterialShell
License:        MIT
URL:            https://github.com/AvengeMedia/dgop
Provides:       dgop

%description -n dgop
DGOP is a stateless system monitoring tool that provides CPU, GPU, memory, and 
network statistics. Designed for integration with DankMaterialShell but can be 
used standalone. This package always includes the latest stable dgop release.

%prep
{{{ git_repo_setup_macro }}}

# Download and extract DGOP binary for target architecture
case "%{_arch}" in
  x86_64)
    DGOP_ARCH="amd64"
    ;;
  aarch64)
    DGOP_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: %{_arch}"
    exit 1
    ;;
esac

wget -O %{_builddir}/dgop.gz "https://github.com/AvengeMedia/dgop/releases/latest/download/dgop-linux-${DGOP_ARCH}.gz" || {
  echo "Failed to download dgop for architecture %{_arch}"
  exit 1
}
gunzip -c %{_builddir}/dgop.gz > %{_builddir}/dgop
chmod +x %{_builddir}/dgop

%build
# Build DMS CLI from source (core/ subdirectory in monorepo)
cd core
make dist

%install
# Install dms-cli binary (built from source) - use architecture-specific path
case "%{_arch}" in
  x86_64)
    DMS_BINARY="dms-linux-amd64"
    ;;
  aarch64)
    DMS_BINARY="dms-linux-arm64"
    ;;
  *)
    echo "Unsupported architecture: %{_arch}"
    exit 1
    ;;
esac

install -Dm755 core/bin/${DMS_BINARY} %{buildroot}%{_bindir}/dms

# Shell completions
install -d %{buildroot}%{_datadir}/bash-completion/completions
install -d %{buildroot}%{_datadir}/zsh/site-functions
install -d %{buildroot}%{_datadir}/fish/vendor_completions.d
core/bin/${DMS_BINARY} completion bash > %{buildroot}%{_datadir}/bash-completion/completions/dms || :
core/bin/${DMS_BINARY} completion zsh > %{buildroot}%{_datadir}/zsh/site-functions/_dms || :
core/bin/${DMS_BINARY} completion fish > %{buildroot}%{_datadir}/fish/vendor_completions.d/dms.fish || :

# Install dgop binary
install -Dm755 %{_builddir}/dgop %{buildroot}%{_bindir}/dgop

# Install systemd user service (from quickshell/ subdirectory)
install -Dm644 quickshell/assets/systemd/dms.service %{buildroot}%{_userunitdir}/dms.service

# Install shell files to shared data location (from quickshell/ subdirectory)
install -dm755 %{buildroot}%{_datadir}/quickshell/dms
cp -r quickshell/* %{buildroot}%{_datadir}/quickshell/dms/

# Remove build files
rm -rf %{buildroot}%{_datadir}/quickshell/dms/.git*
rm -f %{buildroot}%{_datadir}/quickshell/dms/.gitignore
rm -rf %{buildroot}%{_datadir}/quickshell/dms/.github
rm -rf %{buildroot}%{_datadir}/quickshell/dms/distro

%posttrans
# Clean up old installation path from previous versions (only if empty)
if [ -d "%{_sysconfdir}/xdg/quickshell/dms" ]; then
    # Remove directories only if empty (preserves any user-added files)
    rmdir "%{_sysconfdir}/xdg/quickshell/dms" 2>/dev/null || true
    rmdir "%{_sysconfdir}/xdg/quickshell" 2>/dev/null || true
    rmdir "%{_sysconfdir}/xdg" 2>/dev/null || true
fi

# Restart DMS for active users after upgrade
if [ "$1" -ge 2 ]; then
  pkill -USR1 -x dms >/dev/null 2>&1 || true
fi

%files
%license LICENSE
%doc CONTRIBUTING.md
%doc quickshell/README.md
%{_datadir}/quickshell/dms/
%{_userunitdir}/dms.service

%files -n dms-cli
%{_bindir}/dms
%{_datadir}/bash-completion/completions/dms
%{_datadir}/zsh/site-functions/_dms
%{_datadir}/fish/vendor_completions.d/dms.fish

%files -n dgop
%{_bindir}/dgop

%changelog
{{{ git_repo_changelog }}}