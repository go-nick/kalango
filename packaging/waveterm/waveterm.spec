# Repackages Wave's official release RPM.
# Builds have no network: each #!RemoteAsset line makes the build tools download the
# Source below it and check its checksum first. Upstream doesn't sign the RPM, so the
# checksum proves the build used the exact file that was pinned.

# Prebuilt Electron app: nothing to strip or debug. rpm works out the system libraries
# it needs by itself; its bundled libraries are neither offered to the system nor
# required from it.
%global debug_package %{nil}
%global __provides_exclude_from ^/opt/Wave/.*$
%global __requires_exclude ^lib(ffmpeg|EGL|GLESv2|vk_swiftshader|vulkan)\\.so.*$

Name:           waveterm
Version:        0.14.5
Release:        0
Summary:        Open-source terminal with workspaces, previews and AI
License:        Apache-2.0
URL:            https://www.waveterm.dev
#!RemoteAsset:  sha256:fea2046df8deb8c19ade09f22a3e3faa392b000d60c30b8849e2fb18f27a21d0
Source0:        https://github.com/wavetermdev/waveterm/releases/download/v%{version}/waveterm-linux-x86_64-%{version}.rpm
#!RemoteAsset:  sha256:2961c11688c782253260f3094ef85163871b9bcef1cfc21f8e0650170c736828
Source1:        https://raw.githubusercontent.com/wavetermdev/waveterm/v%{version}/LICENSE
BuildRequires:  cpio
# Owns the /usr/share/icons/hicolor folders the icons go into
BuildRequires:  hicolor-icon-theme
# rpmlint checks the launcher entry with desktop-file-validate, from this package
BuildRequires:  desktop-file-utils
ExclusiveArch:  x86_64
# Upstream's requirements that aren't libraries, so rpm can't detect them
Requires:       at-spi2-core
Requires:       xdg-utils

%description
Wave Terminal, repackaged from the official release for kalango.

%prep
%setup -q -c -T
rpm2cpio %{SOURCE0} | cpio -idm --quiet
cp %{SOURCE1} .

%build

%install
cp -a opt usr %{buildroot}/
# Upstream links this in a post-install script; owning it is cleaner
mkdir -p %{buildroot}%{_bindir}
ln -s /opt/Wave/waveterm %{buildroot}%{_bindir}/waveterm
# Ubuntu's AppArmor profile; Tumbleweed doesn't use it
rm %{buildroot}/opt/Wave/resources/apparmor-profile
# Upstream lists no main menu category
sed -i 's/^Categories=TerminalEmulator;$/Categories=System;TerminalEmulator;/' %{buildroot}%{_datadir}/applications/waveterm.desktop

%posttrans
# Replacing upstream's RPM runs its uninstall script after this package is in place,
# and that script deletes /usr/bin/waveterm. Put the link back.
[ -e %{_bindir}/waveterm ] || ln -s ../../opt/Wave/waveterm %{_bindir}/waveterm

%files
%license LICENSE
/opt/Wave
%{_bindir}/waveterm
%{_datadir}/applications/waveterm.desktop
%{_datadir}/icons/hicolor/*/apps/waveterm.png
