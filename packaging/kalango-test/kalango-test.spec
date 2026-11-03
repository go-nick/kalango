Name:           kalango-test
Version:        0.1
Release:        0
Summary:        Test package for the kalango OBS pipeline
License:        Apache-2.0
URL:            https://github.com/go-nick/kalango
BuildArch:      noarch

%description
Installs one text file. Proves that kalango packages build on OBS
and install with zypper.

%prep

%build

%install
mkdir -p %{buildroot}%{_datadir}/kalango-test
echo "kalango OBS pipeline works" > %{buildroot}%{_datadir}/kalango-test/hello.txt

%files
%{_datadir}/kalango-test
