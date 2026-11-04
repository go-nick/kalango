# Packaging

Everything kalango installs that isn't an official openSUSE package ships as an RPM
built on [OBS](https://build.opensuse.org) in
[`home:go-nick:kalango`](https://build.opensuse.org/project/show/home:go-nick:kalango),
for `openSUSE_Tumbleweed` / `x86_64`. Plan and status: [#7](https://github.com/go-nick/kalango/issues/7).

## How it works

- **Git is the source of truth.** Each OBS package syncs from its folder here on `main`
  (scmsync). Merging is releasing. Never `osc commit`.
- **OBS builds in a clean VM with no network.** Only `BuildRequires` exist inside.
- **OBS rebuilds by itself** when a build dependency changes in Tumbleweed (KWin, Qt).
- **OBS signs and publishes** the RPMs. Users get updates with `zypper dup`.

## Layout

```
packaging/
├── Makefile
├── templates/package.spec   # copied by make new
└── <package>/
    ├── <package>.spec       # the RPM recipe
    ├── <package>.changes    # changelog, one entry per change
    ├── <package>-rpmlintrc  # optional: rpmlint findings to ignore, each with a reason
    └── *.patch
```

## Adding a package

Run inside `packaging/` (or `make -C packaging ...` from the repo root):

1. `make new PKG=<name>`, then fill in the `TODO`s in the spec
2. `make build PKG=<name>` until it builds with 0 rpmlint errors
3. Open a PR and merge it
4. `make obs PKG=<name>` once, to create the OBS package
5. `make status PKG=<name>` until it says `succeeded`

For every later change: edit, `make changes PKG=<name> MSG="..."`, merge. OBS rebuilds
by itself.

## Targets

`make help` lists them.

| Target | Runs | Notes |
|---|---|---|
| `new` | copies the template, `osc vc` | Refuses if the folder exists |
| `build` | `download_assets`, `osc build` | Local, same environment as OBS. Works on a copy in `.build/` (gitignored). Asks the root password |
| `changes` | `osc vc -m "$MSG"` | Name and email come from the OBS account |
| `obs` | `osc meta pkg ... -F -` | Points the package at `packaging/<name>` on `main`. Merge first |
| `status` | `osc results` | |
| `buildlog` | `osc buildlog` | rpmlint result is near the end |
| `delete` | `osc rdelete` | Asks first. Warns if the folder is still in Git |

## Spec notes

- `Release: 0`: OBS sets the real release number
- Keep `%prep` and `%build`, even if empty. Don't add an empty `%check`
- `BuildArch: noarch` for packages with nothing compiled

## Sources from the internet

Builds have no network. Mark each downloaded source with `#!RemoteAsset` and its
checksum, on the line above it:

```spec
#!RemoteAsset:  sha256:<checksum>
Source0:        https://example.org/foo-%{version}.tar.gz
```

The build tools download it before the build and refuse a file whose checksum doesn't
match. `make build` keeps downloads in `~/.cache/kalango/assets`, keyed by checksum, so
they aren't fetched again. To get the checksum of a new version:

```
curl -fsSL <url> | sha256sum
```

A version bump changes `Version` and every `#!RemoteAsset` checksum.

## rpmlint

rpmlint checks every build; past a badness of 999 the build fails. Fix what's ours. For
findings that come with upstream's files (prebuilt binaries), add `addFilter("<check>
<path>")` lines to `<package>-rpmlintrc`, as narrow as possible, each with a comment
saying why. See `waveterm/waveterm-rpmlintrc`.

## One-time setup (dev machine)

1. openSUSE account: [idp-portal.suse.com](https://idp-portal.suse.com/univention/self-service/#page=createaccount),
   then log in once at build.opensuse.org to create `home:<user>`
2. `sudo zypper in osc`, then any `osc` command asks for the login. Store the password
   in KWallet
3. The project was created from this XML with `osc meta prj home:go-nick:kalango -F <file>`
   (`osc meta prj -e home:go-nick:kalango` edits it):

```xml
<project name="home:go-nick:kalango">
  <title>kalango</title>
  <description>kalango packages for openSUSE Tumbleweed</description>
  <person userid="go-nick" role="maintainer"/>
  <repository name="openSUSE_Tumbleweed">
    <path project="openSUSE:Factory" repository="snapshot"/>
    <arch>x86_64</arch>
  </repository>
</project>
```

## Installing from the repo

```
sudo zypper ar -f https://download.opensuse.org/repositories/home:/go-nick:/kalango/openSUSE_Tumbleweed/ kalango
sudo zypper in <package>
```

The first refresh asks to trust the project's signing key.
