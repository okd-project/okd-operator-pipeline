# Kata Containers RPM (Fedora COPR) for OKD sandboxed-containers

The [sandboxed-containers operator](../) installs the Kata Containers runtime on
cluster nodes. A default `KataConfig` makes the operator emit a `MachineConfig` that
requests the **`sandboxed-containers` rpm-ostree extension** — the only extension name
the MCO accepts (validated against `SupportedExtensions()` on all OSes), which the MCO
daemon translates to installing the **`kata-containers` package**.

`rpm-ostree` can only install that package if it is **available in a yum repo the node
can reach**. Red Hat ships it in the RHCOS extensions image, but SCOS's extensions image
does not carry it — so we build it ourselves in **Fedora COPR** and enable the resulting
repo on the nodes.

## 1. Build the RPM

Prerequisites: a Fedora account and a COPR API token saved at `~/.config/copr`
(generate one at <https://copr.fedorainfracloud.org/api/>), plus `copr-cli`
(`pip install copr-cli` or `dnf install copr-cli`).

The RPM is published to the COPR project **`owenh/sandboxed-containers-<MAJOR>.<MINOR>`**
(e.g. `owenh/sandboxed-containers-1.13`). The version is the **operator version** — the
`MAJOR`/`MINOR` exported in [`../build.sh`](../build.sh), which the script reads by
default — so the RPMs land in a per-operator-release repo automatically.

```bash
# Defaults: owner owenh, project sandboxed-containers-<MAJOR>.<MINOR> from ../build.sh,
# CentOS Stream 10 chroots (SCOS base for OKD 4.20+). Override as needed:
COPR_OWNER=owenh \
MAJOR=1 MINOR=13 \
CHROOTS="epel-10-x86_64 epel-9-x86_64" \
./copr-build.sh

# Or name the project explicitly:
COPR_PROJECT=sandboxed-containers-1.13 ./copr-build.sh
```

The build is also wired into CI: `.github/workflows/sandboxed-containers-kata-rpm.yaml`
runs this script using the `COPR_API_TOKEN` repository secret (see that workflow for the
secret format). Trigger it via the Actions tab (`workflow_dispatch`) or by pushing changes
under `sandboxed-containers/copr/`.

### Choosing the chroot

The chroot **must match the SCOS base OS of the target OKD release**, or the RPM won't be
installable on the node:

| OKD release | SCOS base        | COPR chroot  |
|-------------|------------------|--------------|
| 4.20+       | CentOS Stream 10 | `epel-10-*`  |
| ≤ 4.19      | CentOS Stream 9  | `epel-9-*`   |

The `epel-N` chroots are used (rather than `centos-stream-N`) because they carry EPEL
in the buildroot — the kata spec `BuildRequires` busybox, which CentOS Stream dropped
and only exists in EPEL. The produced RPMs are el10/el9 and install fine on SCOS;
busybox is also a **runtime** `Requires`, satisfied from EPEL when composing the
extensions payload (see step 2).

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

## 2. Deliver the RPM to the nodes — via the extensions payload

The `kata-containers` RPM **and its dependency closure** (busybox from EPEL,
qemu-kvm-core, virtiofsd, … from CentOS Stream) are delivered to SCOS nodes through the
OKD **extensions payload**, so `rpm-ostree` can resolve the `sandboxed-containers`
extension without any yum repos configured on the nodes. Neither the operator nor any
manual `MachineConfig` configures node-side repos; the COPR repo built above is consumed
when composing the extensions payload, not by the nodes directly.

The operator requests the `sandboxed-containers` extension name — the only name the
MCO's `SupportedExtensions()` validation accepts, which the MCO daemon translates to
installing the `kata-containers` package. Upstream defaults to `kata-containers` on
SCOS (which fails rendering), so [`../build.sh`](../build.sh) `build_bundle()` sets the
operator's supported `SANDBOXED_CONTAINERS_EXTENSION=sandboxed-containers` env override
in the manager deployment before `make bundle`.

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
runs `rpm-ostree` on each targeted node, which installs `kata-containers` from the
extensions payload (step 2) and reboots the node with the Kata runtime available.

## Scope / limitations

Only the **default bare-metal Kata** path is supported on OKD: the operator, kata-monitor,
and must-gather images are rebuilt. Peer-pods and Confidential Containers images
(cloud-api-adaptor, peerpods-webhook, podvm-builder/payload/oci, storage-helper) are not
rebuilt for OKD; their `RELATED_IMAGE_*` references in the CSV still point at
`registry.redhat.io` and will not pull on OKD.
