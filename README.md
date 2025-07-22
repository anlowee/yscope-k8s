# Setup local K8s cluster for presto + clp

## Install docker

Follow the guide here: [docker]

## Install kubectl

`kubectl` is the command-line tool for interacting with Kubernetes clusters. You will use it to
manage and inspect your k3d cluster.

Follow the guide here: [kubectl]

## Install k3d

k3d is a lightweight wrapper to run k3s (Rancher Lab's minimal Kubernetes distribution) in docker.

Follow the guide here: [k3d]

## Install Helm

Helm is the package manager for Kubernetes.

Follow the guide here: [helm]

## Install mysql-client

If you want to use the provided script to setup the metadata databse you may want to install mysql-client.

```bash
sudo apt update && sudo apt install -y mysql-client
```

## Install yq

If you want to use the provided script to setup the values you may want to install yq.

```bash
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
```

# Launch clp-package

1. Find the clp-package for test on our official website [clp-json-v0.4.0]. Here is a sample dataset for demo testing: [postgresql dataset].

2. Untar the clp-package and the postgresql dataset.

3. Replace the content of `/path/to/clp-json-package/etc/clp-config.yml` with the output of `demo-assets/init.sh generate_sample_clp_config`.

4. Launch:

```bash
# You probably want to run a python 3.9 or newer virtual environment
sbin/start-clp.sh
```

5. Compress:

```bash
# You can also use your own dataset
sbin/compress.sh --timestamp-key 'timestamp' /path/to/postgresql.log
```

6. Use the following command to update the CLP metadata database as well as the `values.yaml` used by the helm chart so that the worker can find the archives in right place:

```bash
demo-assets/init.sh update_metadata_config /path/to/clp-json-package
```

# Create k8s Cluster

Create a local k8s cluster with port forwarding

```bash
k3d cluster create yscope --servers 1 --agents 1 -v $(readlink -f /path/to/clp-json-package/var/data/archives):/var/data/archives
```

# Working with helm chart

## Install

```bash
helm template . 

helm install demo .
```

## Use cli:

After all containers are in "Running" states (check by `kubectl get pods`):

```bash
# On your host
kubectl exec -it presto-coordinator -- /bin/bash

# In presto-coordinator container
/opt/presto-cli --catalog clp --schema default --server localhost:8080
```

You can also forward the port of the presto-coordinator to your host:

```bash
kubectl port-forward service/presto-coordinator 8080:8080
```

Then you can access the Presto's WebUI at http://localhost:8080 or use your local presto-cli to connect to the coordinator to run queries.

Example query:
```sql
SELECT * FROM default LIMIT 1;
```

## Uninstall

```bash
helm uninstall demo
```

# Delete k8s Cluster

```bash
k3d cluster delete yscope
```


[clp-json-v0.4.0]: https://github.com/y-scope/clp/releases/tag/v0.4.0
[docker]: https://docs.docker.com/engine/install
[k3d]: https://k3d.io/stable/#installation
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
[helm]: https://helm.sh/docs/intro/install/
[postgresql dataset]: https://zenodo.org/records/10516402

