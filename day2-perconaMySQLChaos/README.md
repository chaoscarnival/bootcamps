# Percona XtraDB (Galera) Node Network Disruption Chaos Workflow


### PreRequisites (only needed if you are doing this demo on your own cluster) 

- Install the [Percona XtraDB cluster](https://www.percona.com/doc/kubernetes-operator-for-pxc/kubernetes.html#install-kubernetes) on Kubernetes with the [Percona 
  Monitoring Management (PMM)](https://www.percona.com/doc/kubernetes-operator-for-pxc/monitoring.html) configured. 

- Install the Litmus (Portal) Control Plane. You can use the step provided in the [Portal Documentation](https://github.com/litmuschaos/litmus/tree/master/litmus-portal#applying-k8s-manifest)

- Setup the [LitmusChaos](https://github.com/chaoscarnival/bootcamps/tree/main/day1-kafkaChaos/chaos-exporter) prometheus exporters
- Setup the ServiceMonitors for [LitmusChaos](https://github.com/chaoscarnival/bootcamps/blob/main/day1-kafkaChaos/service-monitors/chaos-exporter-service-monitor.yaml) prometheus exporters
- Setup the Prometheus monitoring infra via the [Prometheus Operator](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-operator) with suitable [Configuration](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-configuration)
- Apply the [Prometheus CR](https://github.com/chaoscarnival/bootcamps/tree/main/day1-kafkaChaos/prometheus) to scrape metrics from the LitmusChaos exporters

*Please retain only the prometheus scrape configuration needed for this experiment (i.e., chaos exporter). These link shared above contains additional service monitors*

**NOTE**

- The ChaosCarnival bootcamp has an optional lab session for which a prepackaged cluster environment will be provided to interested users for the duration of the lab
- The aforementioned prerequisites have already been setup for these clusters. 

Reach out to [Udit Gaurav](udit.gaurav@mayadata.io) or [Shubham Chaudhary](shubham.chaudhary@mayadata.io)

### UseCase & Hypothesis 

One of the 3 PXC cluster nodes is subjected to network disruption of different durations: (case-a) **3s** & (case-b) **20s** when under client load (simulated by sysbench)

The intent is to verify whether the functionality around the `evs.suspect_timeout` - a variable with default five sec which defines the limit of how long the nodes will 
wait till forming a new quorum without the affected node (percona always recommends odd number of nodes which can sustain failure of (n-1)/2 nodes).

With (case-a), the node is expected to recover with the quorum & quorum members intact without much perceptible change in app (client) behavior (transient stoppage of I/Os)

![image](https://user-images.githubusercontent.com/21166217/107640945-fd928980-6c98-11eb-9f21-841e8786a4b3.png)


With (case-b), the node loses connectivity with resr of the clusters and is marked inactive, with the remaining nodes forming the quorum. The affected node *rejoins* the cluster 
once the network connectivity resumes. Despite the disruption of traffic of 20s, the app (client) only notices a I/O stoppage for 5s (evs.suspect_timeout) post which the I/Os 
continue to be served. 

![image](https://user-images.githubusercontent.com/21166217/107641065-261a8380-6c99-11eb-87dc-515e5a2495b8.png)

Steady State Hypothesis: All PXC noeds are active & part of the quorum. Application (sysbench client) is always alive & running without breaking. 

### Demo Playbook

- Describe the Chaos Workflow manifests describing how network loss is injected on cluster1-pxc-1 vis-a-vis remaining cluster (cluster1-pxc-0,cluster1-pxc-2) & the K8sProbe 
  to verify application (sysbench client) state. 

- Schedule the chaos workflows for [case-a](https://github.com/chaoscarnival/bootcamps/blob/main/day2-perconaMySQLChaos/chaos-workflow/pxc-node-nw-disruption-3s/percona-chaos-wf.yaml) & [case-b](https://github.com/chaoscarnival/bootcamps/blob/main/day2-perconaMySQLChaos/chaos-workflow/pxc-node-nw-disruption-10s/percona-chaos-wf.yaml), with visualization of workflows on the Litmus Portal & chaos-interleaved PMM dashboards 

- Verify the ChaosEngine & ChaosResult Statuses to know the experiment verdict post workflow completion. Sample results (including experiment pod logs, chaosresult dumps, client logs & PXC logs) for both cases can be found [here](https://github.com/chaoscarnival/bootcamps/tree/main/day2-perconaMySQLChaos/results)

More Chaos Scenarios on Percona can be found in [Vadim's talk in ChaosCarnival](https://www.youtube.com/watch?v=fSgtUflRqCU)
