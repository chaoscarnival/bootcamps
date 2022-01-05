# Redis Network Latency, Pod CPU Hog and Pod-io-stress Chaos Workflow


## PreRequisites 

## Step 1. Install redis. You can skip it if redis is already installed 

- Install the `Redis`  along with the `Prometheus Exporter` sidecar in the Kubernetes cluster. Install any one of the below Postgres cluster.
  - Single replica(as a Deployment) [Redis]() 
  - Two nodes(as a StatefulSet) [Redis]()    
- Install the Litmus(ChaosCenter). Follow the step provided in the [Portal Documentation](https://github.com/litmuschaos/litmus/tree/master/litmus-portal#applying-k8s-manifest)

**Note:** Prefered `redis` namespace for postgres cluster and `monitoring` namespace for prometheus and grafana.

## Step 2. Install Load Generator And Monitoring Components

- Install redis load generator for read and write operations. Install any one of the below load generator. Make sure you have already created secret in agent namespace. 
  - Using custom load generator [Deployment manifest]()
  - Using Locust io load generator [Deployment manifest]()
  **Note** : You can update `redisLoadDeployment.yaml` and `redisLoadLocustDeployment.yaml` with required environment variable.
- Install the [Prometheus](https://github.com/litmuschaos/test-tools/tree/master/custom/workflow-helper/postgres-helper/monitoring/prometheus) with correct postgres exporter job details [Configuration](https://github.com/litmuschaos/test-tools/blob/master/custom/workflow-helper/postgres-helper/monitoring/prometheus/02-prometheus-configMap.yaml). If using zalando operator then no need to update configuration.
- Install the [Grafana](https://github.com/litmuschaos/test-tools/tree/master/custom/workflow-helper/postgres-helper/monitoring/k8s-grafana) and use [Dashboard](https://github.com/litmuschaos/test-tools/blob/load/custom/workflow-helper/redis-helper/manifest/dashboard.json/)

## UseCase & Hypothesis

The demo involves using Litmus to inject chaos on a Redis application, at the same time observing & validating some critical redis metrics. More details on what the scenario entails is provided below:

- The experiment begins by generating load on the redis cluster via load generator.
- Network Latency, Pod CPU Hog and Pod-io-stress chaos is injected on redis replica serially, triggering a chaos resulting downtime in a read/write io performance, QPS(DB Query Per Second is reducing)
- Network Latency cause to redis application replica by starting a traffic control (tc) process with netem rules to add egress delays using litmus
- Pod CPU Hog simulates conditions where app pods experience CPU spikes either due to expected/undesired processes thereby testing how the overall redis application stack behaves when this occurs
- Pod-io-stress causes disk stress on the redis application pod
- The application pod should be healthy once chaos is completed. Service-requests should be served despite chaos.

## Scenarios :

### Single replica Scenario:
- Application installed with a single replica as a deployment.
- Experiment Network Latency: Network Latency causes Redis application replica by injecting network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy using litmus. It may stall or get corrupted while they wait endlessly for a packet, due to degradation in access to a downstream/dependent microservice read/write operations are reduced and query per second is affected.
- Experiment Pod CPU Hog: It experiment consumes the CPU resources of the Redis application container due to which the database potential slowness/unavailability of some replicas due to high CPU load until the replica pod restarts.
- Experiment Pod-io-stress: Stressing the disk with continuous and heavy IO, due to degradation in stress reads/write operations are reduced and query per second is decreased.

- We can visualize using the dotted area. 


![image](./results/single-replica/qps.png)
![image](./results/single-replica/qps_rate.png)

- Experiment logs and chaosresult has been added [here](./results/single-replica)

### Two replica Scenario:

- Application installed with two replicas as a statefulset.
- Experiment Network Latency: Network Latency causes Redis application replica by injecting network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy using litmus. due to two replicas even if degradation in access to a downstream/dependent replica is affected another replica is still healthy and read/write operations takes and query per second is not affected. 
- Experiment Pod CPU Hog: Pod CPU Hog consumes the CPU resources of the Redis application replica, due to database potential slowness/unavailability of replica high CPU load until the replica pod restarts. Whereas 2nd replica is continuously healthy which will maintain the resiliency of the application.
- Experiment Pod-io-stress: Stressing the disk with continuous and heavy IO, due to two replicas degradation in stress reads/write operations is not affecting read/write load and the query per second not varying.

![image](./results/two-replica/qps.png)
![image](./results/two-replica/qps_rate.png)

- Experiment logs and chaosresult has been added [here](./results/two-replica).

### Workflow Details

- Redis Network Latency, Pod CPU Hog and Pod-io-stress Chaos Workflow:
  - [workflow](./workflow) using CMDProbe for redis database check, k8sProbe for db CR status check and promProbe for prometheus query benchmark check.

- Workflow use case. 
  - CMDProbe for redis database check plays an important role for identifying the error during chaos injection. We can see both weak and resilient experiment logs to see the error.
  - PromProbe is getting used to check the accessibility of postgresql state and benchmark check for prometheus metrics on a given query.
  - K8sProbe for db CR status check during chaos injection which check for application Resource health state

**Note**: Make sure your runtime should be one of the docker, containerd, or crio. Default is docker.
  - If it is containerd then update chaosengine with`CONTAINER_RUNTIME` and `SOCKET_PATH` with `containerd` and `/run/containerd/containerd.sock` respectively in workflow manifest.
  - If it is crio then update chaosengine with`CONTAINER_RUNTIME` and `SOCKET_PATH` with `crio` and `/run/crio/crio.sock` respectively in workflow manifest.