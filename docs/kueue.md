# What is Kueue?

Kubernetes Kueue is a cloud-native job queueing system designed for batch, HPC, AI/ML, and similar applications running in a Kubernetes cluster. It's important to note that Kueue is not a replacement for existing Kubernetes components, but rather a complementary tool.

[Documentation](https://kueue.sigs.k8s.io/docs/installation)

[Source Code](https://github.com/kubernetes-sigs/kueue)

# Key Features

**Cloud-Native Job Queueing**:
Kueue is designed as a **cloud-native job queueing system** for batch, HPC, AI/ML, and similar applications running in a Kubernetes cluster.

**Resource Management and Quotas**:
- Kueue manages quotas and how jobs consume them.
- It supports building **multi-tenant batch services with quotas** and a hierarchy for sharing resources among teams in an organization.

**Workload Admission Control**:
- Kueue decides when a job should wait, when it should be admitted to start (allowing pod creation), and when it should be preempted (deleting active pods).

**Compatibility with Existing Kubernetes Components**:
- Kueue is designed to work alongside existing Kubernetes components without replacing them.
- It avoids duplicating functionalities already offered by established Kubernetes components for pod scheduling, autoscaling, and job lifecycle management.

**Support for Elastic and Heterogeneous Resources**:
- Kueue is compatible with cloud environments where compute resources are elastic and can be scaled up and down.
- It supports environments with heterogeneous compute resources.

**Integration with Kubernetes Job API**:
- Kueue natively supports the Kubernetes Job API.
- It offers hooks for integrating other custom-built APIs for batch jobs.

**Resource Flavors and Groups**:
- Kueue introduces the concept of ResourceFlavors, which describe available resources in a cluster.
- It supports multiple resource groups within a ClusterQueue, allowing for flexible resource management.

**Quota Reservation and Borrowing**:
- Kueue implements a quota reservation process to lock resources needed by workloads.
- It supports quota borrowing between ClusterQueues within the same cohort.

**Admission Checks**:
- Kueue includes an admission process that allows a Workload to start when it has a Quota Reservation and all its AdmissionCheckStates are Ready.

# Deployment

## Requirements

- Kubernetes cluster with version 1.25 or newer.
- The `SuspendJob` feature gate is enabled. (enabled by default in Kubernetes 1.22 or newer)
- HELM v3.0 or newer is required to install the HELM chart

## HELM

The Kueue HELM chart is not included in the official release artifacts. 
To install Kueue using HELM, you must use the chart from the source code repository.

- Checkout Kueue GitHub repository

```shell
git clone git@github.com:kubernetes-sigs/kueue.git
```

- Install HELM chart

```shell
cd kueue/charts
helm install kueue kueue/ --create-namespace --namespace kueue-system
```

## kubectl

The kubectl manifest is included in the official release artifacts.

- Set Kueue version:

```shell
export kueue_version=0.8.1
```

- Install a released version of Kueue:

```shell
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v${kueue_version}/manifests.yaml
```

- Wait for Kueue to be fully available:

```shell
kubectl wait deploy/kueue-controller-manager --namespace kueue-system --for=condition=available --timeout=5m
```

- Add metrics scraping for prometheus-operator:

```shell
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v${kueue_version}/prometheus.yaml
```

- Add visibility API to monitor pending workloads:

```shell
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v${kueue_version}/visibility-api.yaml
```

# Kueue Concepts

## Resource Flavor

- ResourceFlavors represent variations in cluster resources and allow associating them with nodes through labels, taints, and tolerations.
- To associate a ResourceFlavor with nodes, configure the `.spec.nodeLabels` field with matching labels.
- When admitting a Workload, Kueue evaluates the `.nodeSelector` and `.affinity.nodeAffinity` fields against the ResourceFlavor labels.
- Kueue adds the ResourceFlavor labels and tolerations to the underlying Workload Pod templates.
- To restrict the usage of a ResourceFlavor, configure the `.spec.nodeTaints` field, and the Workload's PodSpecs should have a toleration for it.
- An "empty" ResourceFlavor can be used if the cluster has homogeneous resources or you don't need to manage quotas for different flavors separately.

**ResourceFlavor Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: "spot"
spec:
  nodeLabels:
    instance-type: spot
  nodeTaints:
  - effect: NoSchedule
    key: spot
    value: "true"
  tolerations:
  - key: "spot-taint"
    operator: "Exists"
    effect: "NoSchedule"
```

## Cluster Queue

- A ClusterQueue is a cluster-scoped object that governs a pool of resources like pods, CPU, memory, and hardware accelerators.
- ClusterQueues define quotas for different "flavors" of resources, and assign these flavors to workloads during admission.
- ClusterQueues can be grouped into "cohorts" to allow borrowing of unused quota between them.
- ClusterQueues support various queueing strategies and preemption policies to manage workload admission.
- Administrators can configure "flavor fungibility" to control whether borrowing or preemption is prioritized.
- ClusterQueues can have "stop policies" to temporarily halt admission of new workloads.

**ClusterQueue Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: "cluster-queue"
spec:
  namespaceSelector: {} # match all.
  resourceGroups:
  - coveredResources: ["cpu", "memory", "foo.com/gpu"]
    flavors:
    - name: "spot"
      resources:
      - name: "cpu"
        nominalQuota: 9
      - name: "memory"
        nominalQuota: 36Gi
      - name: "foo.com/gpu"
        nominalQuota: 50
    - name: "on-demand"
      resources:
      - name: "cpu"
        nominalQuota: 18
      - name: "memory"
        nominalQuota: 72Gi
      - name: "foo.com/gpu"
        nominalQuota: 100
  - coveredResources: ["bar.com/license"]
    flavors:
    - name: "pool1"
      resources:
      - name: "bar.com/license"
        nominalQuota: 10
    - name: "pool2"
      resources:
      - name: "bar.com/license"
        nominalQuota: 10
```

## Local Queue

- A LocalQueue is a namespaced object that groups related Workloads for a single namespace or tenant.
- A LocalQueue points to a ClusterQueue from which resources are allocated to run its Workloads.
- Users submit jobs to a LocalQueue instead of directly to a ClusterQueue.
- Tenants can discover available queues by listing the local queues in their namespace.
- The commands `queue` and `queues` are aliases for `localqueue`.
- The text asks "What's next?" and invites feedback on whether the page was helpful.

**LocalQueue Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: LocalQueue
metadata:
  namespace: team-a 
  name: team-a-queue
spec:
  clusterQueue: cluster-queue 
```

## Workload

- Workloads are applications that run to completion, composed of one or more Pods.
- Kueue manages Workload objects that represent the resource requirements of a workload, rather than directly manipulating Job objects.
- Workloads can be stopped or resumed by setting the `Active` field, and can be assigned to a specific `LocalQueue`.
- Workloads are composed of `podSets`, which have resource requests used by Kueue to calculate the quota used by the Workload.
- Workloads have a priority that influences the order in which they are admitted by a `ClusterQueue`, which can be set using `Pod Priority` or `WorkloadPriority`.
- Kueue supports custom workload APIs by allowing the creation of corresponding Workload objects.

**Workload Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: Workload
metadata:
  name: sample-job
  namespace: team-a
spec:
  active: true
  queueName: team-a-queue
  podSets:
  - count: 3
    name: main
    template:
      spec:
        containers:
        - image: gcr.io/k8s-staging-perf-tests/sleep:latest
          imagePullPolicy: Always
          name: container
          resources:
            requests:
              cpu: "1"
              memory: 200Mi
        restartPolicy: Never
```

## Workload Priority Class

- WorkloadPriorityClass allows controlling the priority of a workload without affecting the pod's priority.
- WorkloadPriorityClass objects are cluster-scoped and can be used by jobs in any namespace.
- To use WorkloadPriorityClass on Jobs, set the `kueue.x-k8s.io/priority-class` label.
- The `PriorityClassName` field can accept either PriorityClass or WorkloadPriorityClass names.
- The `priorityClassSource` field indicates whether PriorityClass or WorkloadPriorityClass is being used.
- The Workload's priority is mutable, allowing priority updates based on policies, but the `PriorityClassSource` and `PriorityClassName` fields are immutable.
  
**WorkloadPriorityClass Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: WorkloadPriorityClass
metadata:
  name: sample-priority
value: 10000
description: "Sample priority"
```

## Admission Check

- Admission Checks are a mechanism that allows Kueue to consider additional criteria before admitting a Workload.
- AdmissionCheck is a non-namespaced API object used to define details about an admission check.
- AdmissionChecks can be referenced in the ClusterQueue's spec, either by name or by strategy.
- AdmissionCheckStates represent the state of an AdmissionCheck for a specific Workload, with possible states of Pending, Ready, Retry, and Rejected.
- Kueue ensures the list of AdmissionCheckStates is in sync with the Workload's ClusterQueue.
- A Workload is only admitted when all of its AdmissionChecks are in the Ready state.

**AdminssionCheck Example:**

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: AdmissionCheck
metadata:
  name: prov-test
spec:
  controllerName: kueue.x-k8s.io/provisioning-request
  parameters:
    apiGroup: kueue.x-k8s.io
    kind: ProvisioningRequestConfig
    name: prov-test-config
```

## Preemption

- Preemption allows a Workload to evict one or more Workloads from a ClusterQueue with preemption enabled.
- Kueue offers two preemption algorithms: Classic Preemption and Fair Sharing.
- Classic Preemption allows preemption only when the preempting ClusterQueue is running over its nominal quota.
- Fair Sharing allows preemption to achieve equal or weighted share of borrowable resources among ClusterQueues.
- Kueue assigns a numeric "share value" to each ClusterQueue to track its usage of borrowed resources.
- The `preemptionStrategies` field in the Kueue Configuration controls the constraints for preemption.

**Preemption Example:**

Use Kueue Configuration to enable fair sharing preemption strategy.

```yaml
apiVersion: config.kueue.x-k8s.io/v1beta1
kind: Configuration
fairSharing:
  enable: true
  preemptionStrategies: [LessThanOrEqualToFinalShare, LessThanInitialShare]
```

# Manager Kueue

## Role Base Access Control (RBAC)

Kueue deployment creates two primary ClusterRoles to manage access for different user types:

1. **kueue-batch-admin-role**: Grants permissions to manage ClusterQueues, Queues, Workloads, and ResourceFlavors.
2. **kueue-batch-user-role**: Allows management of Jobs and viewing of Queues and Workloads.

To assign the `kueue-batch-admin-role` to a batch administrator (e.g., admin@example.com), create a ClusterRoleBinding using a manifest like this:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods
subjects:
- kind: User
  name: admin@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: kueue-batch-admin-role
  apiGroup: rbac.authorization.k8s.io
```

## Cluster Quotas

- Cluster resource quotas can be managed using a single **ClusterQueue** and **ResourceFlavor** setup.
- Multiple ResourceFlavors can be defined to handle different CPU architectures (e.g., x86 and arm).
- ClusterQueues can borrow unused quota from other ClusterQueues in the same cohort, with an optional borrowing limit.
- A ClusterQueue can have dedicated and fallback flavors to provide a tenant-specific quota and shared quota.
- Administrators can exclude certain resources from the ClusterQueue quota management by specifying resource prefixes in the Kueue configuration.
- The page is intended for batch administrators to manage fair sharing of cluster resources among tenants.

### Create a ClusterQueue

Create a single ClusterQueue to represent the resource quotas for your entire cluster.

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: "cluster-queue"
spec:
  namespaceSelector: {} # match all.
  resourceGroups:
  - coveredResources: ["cpu", "memory"]
    flavors:
    - name: "default-flavor"
      resources:
      - name: "cpu"
        nominalQuota: 9
      - name: "memory"
        nominalQuota: 36Gi
```

### Create a ResourceFlavor

To complete the ClusterQueue setup, define the default flavor. A resource flavor typically includes node labels or taints to specify which nodes can provide it. In this case, use a single flavor to represent all available cluster resources. Create a simple ResourceFlavor without specific node selectors or taints.

Create an empty ResourceFlavor:

1. Define a ResourceFlavor object.
2. Name it to match the flavor specified in the ClusterQueue.
3. Leave the spec empty to match all nodes.

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: "default-flavor"
```

### Create LocalQueues

Users cannot directly send workloads to ClusterQueues. Send workloads to a Queue in your namespace instead. Create a Queue in each namespace that requires access to the ClusterQueue to complete the queuing system.

The manifest for the Queue should resemble the following:

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: LocalQueue
metadata:
  namespace: "default"
  name: "user-queue"
spec:
  clusterQueue: "cluster-queue"
```

# Run Workloads

## Kubernetes Job

### Identify the queues available in your namespace
  
```shell
kubectl -n default get queues
```

### Define the Kubernetes Job

Running a Job in Kueue is similar to running a Job in a Kubernetes cluster without Kueue. However, consider the following differences:

1. Create the Job in a **suspended state**. Kueue will determine the optimal time to start the Job.
2. Set the Queue for Job submission using the kueue.x-k8s.io/queue-name label.
3. Include resource requests for each Job Pod.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  generateName: sample-job-
  namespace: default
  labels:
    kueue.x-k8s.io/queue-name: user-queue
spec:
  parallelism: 3
  completions: 3
  suspend: true
  template:
    spec:
      containers:
      - name: dummy-job
        image: gcr.io/k8s-staging-perf-tests/sleep:v0.1.0
        args: ["30s"]
        resources:
          requests:
            cpu: 1
            memory: "200Mi"
      restartPolicy: Never
```

### Run the Kubernetes Job

Run Kubernetes Job

```shell
kubectl create -f sample-job.yaml
```

Internally, Kueue creates a corresponding Workload for this Job with a matching name. The Workload monitors the Job status and enforces scheduling policies defined in the ClusterQueue and ResourceFlavor configurations.

List Kueue Workloads:

```shell
kubectl -n default get workloads
```

