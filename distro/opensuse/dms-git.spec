%global debug_package %{nil}

Name:           dms-git
Version:        0.6.2+git2147.03073f68
Release:        5%{?dist}
Epoch:          1
Summary:        DankMaterialShell - Material 3 inspired shell (git nightly)

License:        MIT
URL:            https://github.com/AvengeMedia/DankMaterialShell
Source0:        dms-git-source.tar.gz
Source1:        dms-distropkg-amd64.gz
Source2:        dms-distropkg-arm64.gz

BuildRequires:  gzip
BuildRequires:  systemd-rpm-macros

Requires:       (quickshell-git or quickshell)
Requires:       accountsservice
Requires:       dgop

Recommends:     cava
Recommends:     cliphist
Recommends:     danksearch
Recommends:     matugen
Recommends:     quickshell-git
Recommends:     wl-clipboard

Recommends:     NetworkManager
Recommends:     qt6-qtmultimedia
Suggests:       qt6ct

Provides:       dms
Conflicts:      dms
Obsoletes:      dms

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for niri, Hyprland, Sway, and other wlroots compositors.

This git version tracks the master branch and includes the latest features
and fixes. Includes pre-built dms CLI binary and QML shell files.

%prep
%setup -q -n dms-git-source

%ifarch x86_64
gunzip -c %{SOURCE1} > dms
%endif
%ifarch aarch64
gunzip -c %{SOURCE2} > dms
%endif
chmod +x dms

%build

%install
install -Dm755 dms %{buildroot}%{_bindir}/dms

install -d %{buildroot}%{_datadir}/bash-completion/completions
install -d %{buildroot}%{_datadir}/zsh/site-functions
install -d %{buildroot}%{_datadir}/fish/vendor_completions.d
./dms completion bash > %{buildroot}%{_datadir}/bash-completion/completions/dms || :
./dms completion zsh > %{buildroot}%{_datadir}/zsh/site-functions/_dms || :
./dms completion fish > %{buildroot}%{_datadir}/fish/vendor_completions.d/dms.fish || :

install -Dm644 quickshell/assets/systemd/dms.service %{buildroot}%{_userunitdir}/dms.service

install -dm755 %{buildroot}%{_datadir}/quickshell/dms
cp -r quickshell/* %{buildroot}%{_datadir}/quickshell/dms/

rm -rf %{buildroot}%{_datadir}/quickshell/dms/.git*
rm -f %{buildroot}%{_datadir}/quickshell/dms/.gitignore
rm -rf %{buildroot}%{_datadir}/quickshell/dms/.github
rm -rf %{buildroot}%{_datadir}/quickshell/dms/distro
rm -rf %{buildroot}%{_datadir}/quickshell/dms/core

%posttrans
if [ -d "%{_sysconfdir}/xdg/quickshell/dms" ]; then
    rmdir "%{_sysconfdir}/xdg/quickshell/dms" 2>/dev/null || true
    rmdir "%{_sysconfdir}/xdg/quickshell" 2>/dev/null || true
fi

if [ "$1" -ge 2 ]; then
  pkill -USR1 -x dms >/dev/null 2>&1 || true
fi

%files
%license LICENSE
%doc CONTRIBUTING.md
%doc quickshell/README.md
%{_bindir}/dms
%dir %{_datadir}/fish
%dir %{_datadir}/fish/vendor_completions.d
%{_datadir}/fish/vendor_completions.d/dms.fish
%dir %{_datadir}/zsh
%dir %{_datadir}/zsh/site-functions
%{_datadir}/zsh/site-functions/_dms
%{_datadir}/bash-completion/completions/dms
%dir %{_datadir}/quickshell
%{_datadir}/quickshell/dms/
%{_userunitdir}/dms.service

%changelog
* Tue Nov 25 2025 Avenge Media <AvengeMedia.US@gmail.com> - 0.6.2+git2147.03073f68-1
- Git snapshot (commit 2147: 03073f68)
* Fri Nov 22 2025 AvengeMedia <maintainer@avengemedia.com> - 0.6.2+git-5
- Git nightly build from master branch
- Multi-arch support (x86_64, aarch64)
