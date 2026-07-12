# Kata Containers RPM (Fedora COPR) for OKD sandboxed-containers

The [sandboxed-containers operator](../) installs the Kata Containers runtime on
cluster nodes. On SCOS (OKD's CentOS Stream CoreOS), a default `KataConfig` makes the
operator emit a `MachineConfig` that requests the **`kata-containers` rpm-ostree
extension** (see `controllers/openshift_controller.go`, `getExtensionName()` returns
`kata-containers` for `quay.io/okd/scos-release` clusters).

`rpm-ostree` can only install that extension if the **`kata-containers` RPM is available
in a yum repo the node can reach**. Red Hat ships this RPM in the RHCOS extensions image,
but that content is not available on OKD — so we build it ourselves in **Fedora COPR** and
enable the resulting repo on the nodes.

## 1. Build the RPM

Prerequisites: a Fedora account and a COPR API token saved at `~/.config/copr`
(generate one at <https://copr.fedorainfracloud.org/api/>), plus `copr-cli`
(`pip install copr-cli` or `dnf install copr-cli`).

```bash
# Defaults target the okderators COPR + CentOS Stream 10 (SCOS base for OKD 4.20+).
COPR_OWNER=okderators \
COPR_PROJECT=sandboxed-containers-kata \
CHROOTS="centos-stream-10-x86_64 centos-stream-10-aarch64" \
./copr-build.sh
```

The build is also wired into CI: `.github/workflows/sandboxed-containers-kata-rpm.yaml`
runs this script using the `COPR_API_TOKEN` repository secret (see that workflow for the
secret format). Trigger it via the Actions tab (`workflow_dispatch`) or by pushing changes
under `sandboxed-containers/copr/`.

### Choosing the chroot

The chroot **must match the SCOS base OS of the target OKD release**, or the RPM won't be
installable on the node:

| OKD release | SCOS base        | COPR chroot            |
|-------------|------------------|------------------------|
| 4.20+       | CentOS Stream 10 | `centos-stream-10-*`   |
| ≤ 4.19      | CentOS Stream 9  | `centos-stream-9-*`    |

Confirm with `oc adm release info quay.io/okd/scos-release:<version>` or the OKD release
notes before building for a new OKD version.

### Choosing the spec source

`copr-build.sh` defaults to Fedora dist-git (`rpms/kata-containers`, `rawhide` branch),
which carries `kata-containers.spec` and a lookaside `sources` file that COPR's `rpkg`
method resolves automatically. If you need a spec pinned to the CentOS Stream package set,
override the source, e.g.:

```bash
KATA_CLONE_URL=https://gitlab.com/redhat/centos-stream/rpms/kata-containers.git \
KATA_COMMITTISH=c10s \
./copr-build.sh
```

You can also build from a prebuilt SRPM with `KATA_SRPM=<url-or-path>`.

## 2. Enable the repo on SCOS nodes

Publishing the RPM is not enough — the nodes need the COPR repo configured so
`rpm-ostree` can resolve the `kata-containers` extension. Apply a `MachineConfig` that
drops a `.repo` file on the worker pool **before** creating the `KataConfig`. Replace
`<owner>`/`<project>` and confirm the chroot matches your nodes' arch/OS.

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 50-kata-copr-repo
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        - path: /etc/yum.repos.d/kata-containers-copr.repo
          mode: 0644
          overwrite: true
          contents:
            # data:,<url-encoded ini below>
            source: >-
              data:,%5Bcopr-kata-containers%5D%0Aname%3DCopr%20repo%20-%20kata-containers%0Abaseurl%3Dhttps%3A%2F%2Fdownload.copr.fedorainfracloud.org%2Fresults%2Fokderators%2Fsandboxed-containers-kata%2Fcentos-stream-10-%24basearch%2F%0Aenabled%3D1%0Agpgcheck%3D1%0Agpgkey%3Dhttps%3A%2F%2Fdownload.copr.fedorainfracloud.org%2Fresults%2Fokderators%2Fsandboxed-containers-kata%2Fpubkey.gpg%0A
```

The decoded `.repo` contents are:

```ini
[copr-kata-containers]
name=Copr repo - kata-containers
baseurl=https://download.copr.fedorainfracloud.org/results/okderators/sandboxed-containers-kata/centos-stream-10-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/okderators/sandboxed-containers-kata/pubkey.gpg
```

> Tip: regenerate the `data:,` URL from an edited `.repo` file with
> `python3 -c 'import sys,urllib.parse;print("data:,"+urllib.parse.quote(open(sys.argv[1]).read()))' kata-containers-copr.repo`.

## 3. Install the operator and create a KataConfig

```bash
oc create -f https://.../sandboxed-containers-operator-bundle   # via OLM / operator-sdk run bundle
oc apply -f - <<'EOF'
apiVersion: kataconfiguration.openshift.io/v1
kind: KataConfig
metadata:
  name: example-kataconfig
EOF
```

The operator creates the `50-enable-sandboxed-containers-extension` MachineConfig; the MCO
runs `rpm-ostree` on each targeted node, which pulls `kata-containers` from the COPR repo
enabled in step 2 and reboots the node with the Kata runtime available.

## Scope / limitations

Only the **default bare-metal Kata** path is supported on OKD. Peer-pods and Confidential
Containers (cloud-api-adaptor, podvm, PCCS, TDX-QGS) and the kata-monitor image are not
rebuilt for OKD; their `RELATED_IMAGE_*` references in the CSV still point at
`registry.redhat.io` and will not pull on OKD.
