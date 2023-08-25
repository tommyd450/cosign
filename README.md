# Red Hat SecureSign Cosign

This repository holds the Red Hat fork of
`sigstore/cosign` with modifications needed only for Red Hat.

## Mirroring upstream

### Mirroring HEAD from upstream `main`

The HEAD of the upstream repo, `sigstore/cosign` is mirrored on the
`release-next` and `release-next-ci` branches using the [`redhat/release/update-to-head.sh`](redhat/release/update-to-head.sh) script. When this script is run without any arguments, the following steps are taken.

- The upstream HEAD is fetched and checked out as the `release-next` branch
- The `origin` remote `main` branch is pulled and Red-Hat-specific files from that branch are applied to the `release-next` branch
- The `release-next` branch is force pushed to the `origin` remote
- The `release-next` branch is duplicated to `release-next-ci`
- A timestamp file is added to `release-next-ci` branch
- The `release-next-ci` branch is force pushed to the `origin` remote
- A pull request is created (if it does not already exist) for this change, to trigger a CI run
- OpenShift CI runs the upstream unit and integration tests on the PR

### Mirroring releases from upstream release branches

Branches for specific versions may also be managed using this script by supplying a `git-ref` when running the script.

```
./redhat/release/update-to-head.sh v2.1.1
```

To mirror a release branch from upstream, a branch for our midstream changes must exist. The naming for this branch is in the form `midstream-vX.Y.Z` where `vX.Y.Z` corresponds to an upstream release branch. For example, to mirror, modify and test the upstream version `v2.1.1` from your local laptop, you would take the following steps.

1. Ensure the patch file from `main` and any other modifications we make in midstream cleanly applies on the upstream release branch. If it doesn't fix that first.
2. Push a new branch based on our midstream `main` - e.g. `git push origin main:midstream-v2.1.1`
3. Run `./redhat/release/update-to-head.sh v2.1.1`, providing `v2.1.1` as the upstream branch to mirror.

This will create a new "release" branch of the form `redhat-vX.Y.Z`, in this case `redhat-v2.1.1` and a corresponding CI branch for testing, `redhat-v2.1.1-ci`. Then a PR is opened to apply these changes to the midstream release branch, `redhat-v2.1.1`. If OpenShift CI has been configured for this new branch, it will run the unit and integration tests from upstream on the PR.

## Local configuration

To use this script locally, you'll need to have two git remotes for this repository.

- `upstream` pointing to `sigstore/cosign`
- `origin` pointing to `securesign/cosign` (this repo)

### Example to mirror the upstream v2.1.1 release and kick off CI
```
git clone git@github.com:securesign/cosign.git
cd cosign
# Ensure that the patches cleanly apply
git push origin main:midstream-v2.1.1
# Add upstream as a remote
git remote add upstream git@github.com/sigstore/cosign.git
# Run the update script
./redhat/release/update-to-head.sh v2.1.1
```
This should create the `redhat-v2.1.1` branch as well as a test branch at `redhat-v2.1.1-ci`, create a pull request, and initiate OpenShift CI.