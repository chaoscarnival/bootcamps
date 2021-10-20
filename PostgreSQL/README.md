# PostgreSQL Network Disruption and Pod Delete Chaos Workflow


## PreRequisites 

## Step 1. Install Postgres using Zalando Operator. You can skip it if Postgres is already installed 

- Install the [Configurations](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/configuration.yaml) in the Kubernetes cluster

- Install the [Operator](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/operator.yaml) in the Kubernetes cluster

- Install the `Postgres Cluster`  along with the `Prometheus Exporter` sidecar in the Kubernetes cluster. Install any one of the below Postgres cluster.
  - Single node(only master) [Postgres Cluster](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/weak-postgres-manifest.yaml) 
  - Two nodes(master & slave) [Postgres Cluster](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/resilient-postgres-manifest.yaml)    
- Install the Litmus(ChaosCenter). Follow the step provided in the [Portal Documentation](https://github.com/litmuschaos/litmus/tree/master/litmus-portal#applying-k8s-manifest)

- Get the password by executing the given command `echo $(kubectl get secret zalando.postgres-application.credentials -n postgres -o 'jsonpath={.data.password}')`. It is required  to run cmdProbe inside workflow and to generate the load(via load-generator). It should be provided inside the `secret.yaml` file(will see in next/2nd step)

**Note:** Prefered `postgres` namespace for postgres cluster and `monitoring` namespace for prometheus and grafana.

## Step 2. Install Load Generator And Monitoring Components

- Update host, dbname, username, password and port in [secret.yaml](https://github.com/litmuschaos/test-tools/blob/master/custom/workflow-helper/postgres-helper/application/secret.yaml) file. 
  
  **Note**: 
    - Values can be taken from application secret/config file and Apply it in litmus agent namespace. 
    - The values should be provided in encoded (Base64-encoded DER) format. 
      Example: `echo 'postgres' | base64`, 
      Output is `cG9zdGdyZXMK`
      update this encoded value in `secret.yaml` manifest. 
    - If  Zalando operator was used to install postgres then update only the password field, other values should remain the same(default).

- Install postgres load generator for read and write operations. Install any one of the below load generator. Make sure you have already created secret in agent namespace. 
  - Using custom load generator [Deployment manifest](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/deploy-load.yaml)
  - Using Jmeter load generator [Deployment manifest](https://raw.githubusercontent.com/litmuschaos/test-tools/master/custom/workflow-helper/postgres-helper/application/deploy-jmeter.yaml)
  
  **Note** : You can update `deploy-load.yaml` and `deploy-jmeter.yaml` with required environment variable.
- Install the [Prometheus](https://github.com/litmuschaos/test-tools/tree/master/custom/workflow-helper/postgres-helper/monitoring/prometheus) with correct postgres exporter job details [Configuration](https://github.com/litmuschaos/test-tools/blob/master/custom/workflow-helper/postgres-helper/monitoring/prometheus/02-prometheus-configMap.yaml). If using zalando operator then no need to update configuration.
- Install the [Grafana](https://github.com/litmuschaos/test-tools/tree/master/custom/workflow-helper/postgres-helper/monitoring/k8s-grafana) and use [Dashboard](https://github.com/litmuschaos/test-tools/blob/master/custom/workflow-helper/postgres-helper/monitoring/k8s-grafana/dashboard.json) to moniter.

## UseCase & Hypothesis

- Network loss and pod-delete chaos is injected on postgresql master pod. 
- Network loss cause to application master node by injecting packet loss using litmus
- Pod Delete cause (forced/graceful) failure of master pod of an application. Tests deployment sanity (node availability & uninterrupted service) and recovery workflow of the application
- The application pod should be healthy once chaos is completed. Service-requests should be served despite chaos.

## Scenarios :

### Single node(master) Scenario:
- Application installed with single node(master) as a statefulset.
- Experiment Network-Loss: It disrupts the accessibility of postgres endpoints that blocks the read and write operations.
- Experiment Pod-Delete: It deletes the master pod due to which the database remains in an inaccessible state until the master pod restarts. It blocks read/write operations when the master pod terminates. 
- We can visualize the network loss with the first red dotted area and pod-delete by the second red dotted area. 

![image](https://github.com/oumkale/bootcamps/blob/postgres/PostgreSQL/results/single-master-node/graphs/weak-resilient-insertion-rate-dashboard.png)
![image](https://github.com/oumkale/bootcamps/blob/postgres/PostgreSQL/results/single-master-node/graphs/weak-insertion-rate-and-deletion-rate-dashboard.png)

- Experiment logs and chaosresult has been added [here](https://github.com/oumkale/bootcamps/tree/postgres/PostgreSQL/results/weak).

### Two node(master-slave) Scenario:

- Application installed with two node(master-slave) as a statefulset.
- Experiment Network-Loss: Due to network loss the master pod is inaccessible after some downtime the slave becomes master and the master becomes a slave. Due to database accessible Read-Write requests get succeed. Postgres operator carries out the rolling update, it re-spawns pods of each managed StatefulSet one by one with the master-slave.
- Experiment Pod-Delete: Once the master pod is terminated the slave will become master immediately and keep available. Due to database accessibility, Read-Write requests get succeed.

![image](https://github.com/oumkale/bootcamps/blob/postgres/PostgreSQL/results/two-node-master-slave/graphs/resilient-insertion-rate-dashboard.png)
![image](https://github.com/oumkale/bootcamps/blob/postgres/PostgreSQL/results/two-node-master-slave/graphs/resilient-insertion-rate-and-deletion-rate-dashboard.png)

- Experiment logs and chaosresult has been added [here](https://github.com/oumkale/bootcamps/tree/postgres/PostgreSQL/results/resilient).

**Note** : In a two-node(master-slave) cluster during network loss, there is downtime from Postgres. This is because it takes a certain amount of time to check accessibility with the current master role and once it achieves the max time limit, Immediately transfer the master role to the slave during the chaos. In master, pod delete there is no other way than allowing the master role to slave since the master is deleted.

### Workflow Details

- PostgreSQL Network Disruption and Pod Delete Chaos workflow:
  - [workflow](https://github.com/oumkale/bootcamps/blob/postgres/PostgreSQL/workflow/workflow-prom.yaml) using CMDProbe for postgres database check and promProbe for prometheus query benchmark check.

- Workflow use case. 
  - CMDProbe for postgres database check plays an important role for identifying the error during chaos injection. We can see both weak and resilient experiment logs to see the error.
  - PromProbe is getting used to check the accessibility of postgresql state and benchmark check for prometheus metrics on a given query.

**Note**: Make sure your runtime should be one of the docker, containerd, or crio. Default is docker.
  - If it is containerd then update chaosengine with`CONTAINER_RUNTIME` and `SOCKET_PATH` with `containerd` and `/run/containerd/containerd.sock` respectively in workflow manifest.
  - If it is crio then update chaosengine with`CONTAINER_RUNTIME` and `SOCKET_PATH` with `crio` and `/run/crio/crio.sock` respectively in workflow manifest.