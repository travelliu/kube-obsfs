## Shared storage with OBS backend

kube-obs is modified based on open source [kube-s3](https://github.com/freegroup/kube-s3).


The storage is definitely the most complex and important part of an application setup, once this part is
completed, 80% of the tasks are completed.

Mounting an OBS bucket into a pod using FUSE allows you to access the data as if it were on the local disk. The
mount is a pointer to an OBS location, so the data is never synced locally. Once mounted, any pod can read or even write
from that directory without the need for explicit keys.


However, it can be used to import and parse large amounts of data into a database.



## Limitations
Generally OBS cannot offer the same performance or semantics as a local file system. More specifically:

 - random writes or appends to files require rewriting the entire file
 - metadata operations such as listing directories have poor performance due to network latency
 - eventual consistency can temporarily yield stale data(Amazon S3 Data Consistency Model)
 - no atomic renames of files or directories
 - no coordination between multiple clients mounting the same bucket
 - no hard links

## Docker Test

```bash
docker run -d -e OBSFS_BUCKET=xxx \
    -e OBSFS_ACCESS_KEY=xxxx \
    -e OBSFS_SECRET_KEY=xxxxx \
    -e OBSFS_ENDPOINT=obs.cn-north-4.myhuaweicloud.com \
    --device /dev/fuse --privileged \
    --name kube-obsfs \
    travelliu/kube-obsfs

docker exec -it kube-obsfs bash
cd /var/obsfs
ls
```

## Before you Begin
You need to have a Kubernetes cluster, and the kubectl command-line tool must be configured to communicate with
your cluster. If you do not already have a cluster, you can create one by using the [Gardener](https://gardener.kubernetes.sap.corp/login).

Ensure that you have create the "imagePullSecret" in your cluster.
```sh
kubectl create secret docker-registry artifactory --docker-server=<YOUR-REGISTRY>.docker.repositories.sap.ondemand.com --docker-username=<USERNAME> --docker-password=<PASSWORD> --docker-email=<EMAIL> -n <NAMESPACE>
```

## Setup

The first step is to clone this repository. Next is the Secret for the AWS API credentials of the user that has
full access to our S3 bucket. Copy the `configmap_secrets_template.yaml` to `configmap_secrets.yaml` and place
your secrets at the right place.

Region endpoint address: Obtain the region information and endpoint address according to the region where the mounted parallel file system resides. For details, see [Regions and Endpoints.](https://developer.huaweicloud.com/endpoint?OBS)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: obs-config
data:
  OBSFS_BUCKET: <YOUR-OBS-BUCKET-NAME>
  OBSFS_ACCESS_KEY: <YOUR-OBS-ACCESS-KEY>
  OBSFS_SECRET_KEY: <YOUR-OBS-SECRET-KEY>
  # https://developer.huaweicloud.com/endpoint?OBS
  OBSFS_ENDPOINT: <YOUR-OBS-ENDPOINT>
```

## Build and deploy
Change the settings in the `build.sh` file with your docker registry settings.

```sh
#!/usr/bin/env bash

########################################################################################################################
# PREREQUISTITS
########################################################################################################################
#
# - ensure that you have a valid Artifactory or other Docker registry account
# - Create your image pull secret in your namespace
#   kubectl create secret docker-registry artifactory --docker-server=<YOUR-REGISTRY>.docker.repositories.sap.ondemand.com --docker-username=<USERNAME> --docker-password=<PASSWORD> --docker-email=<EMAIL> -n <NAMESPACE>
# - change the settings below arcording your settings
#
# usage:
# Call this script with the version to build and push to the registry. After build/push the
# yaml/* files are deployed into your cluster
#
#  ./build.sh 1.0
#
VERSION=$1
PROJECT=kube-obsfs
REPOSITORY=travelliu


# causes the shell to exit if any subcommand or pipeline returns a non-zero status.
set -e
# set debug mode
#set -x

.
.
.
.

```
Create the OBSFS Fuse Pod and check the status:

```sh
# build and push the image to your docker registry
./build.sh 1.0

# check that the pods are up and running
kubectl get pods

```

## Check success
Create a demo Pod and check the status:
```sh
kubectl apply -f ./yaml/example_pod.yaml

# wait some second to get the pod up and running...
kubectl get pods

# go into the pd and check that the /var/obs is mounted with your OBS bucket content inside
kubectl exec -ti test-pd  sh

# inside the pod
ls -la /var/obsfs

```

## Why does this work?
Docker engine 1.10 added a new feature which allows containers to share the host mount namespace. This feature makes
it possible to mount a s3fs container file system to a host file system through a shared mount, providing a persistent
network storage with OBS backend.

The key part is mountPath: `/var/obs:shared` which enables the volume to be mounted as shared inside the pod. When the
container starts it will mount the OBS bucket onto `/var/obs` and consequently the data will be available under
`/mnt/data-obsfs` on the host and thus to any other container/pod running on it (and has `/mnt/data-obsfs` mounted too).
