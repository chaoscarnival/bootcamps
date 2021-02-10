# Kafka Broker Pod Failure Chaos Workflow 


### PreRequisites (only needed if you are doing this demo on your own cluster) 

- Install Kafka Cluster on Kubernetes (the demo uses [KUDO](https://kudo.dev/docs/runbooks/kafka/install.html#installing-the-operator) to install this)
- Install the Litmus (Portal) Control Plane. You can use the step provided in the [Portal Documentation](https://github.com/litmuschaos/litmus/tree/master/litmus-portal#applying-k8s-manifest)
- Setup the [Kafka](./kafka-exporter-helm) (via helm) & [LitmusChaos](./chaos-exporter) prometheus exporters
- Setup the ServiceMonitors for [Kafka](./service-monitors/kafka-exporter-service-monitor.yaml) & [LitmusChaos](./service-monitors/chaos-exporter-service-monitor.yaml) prometheus exporters
- Setup the Prometheus monitoring infra via the [Prometheus Operator](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-operator) with suitable [Configuration](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-configuration)
- Apply the [Prometheus CR](./prometheus/prometheus.yaml) to scrape metrics from the Kafka & LitmusChaos exporters
- (Optional) Setup [Grafana](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/grafana) to view the Kafka & LitmusChaos metrics. This [sample](./grafana/dashboard.json) dashboard JSON can be used.

**NOTE**

- The ChaosCarnival bootcamp has an optional lab session for which a prepackaged cluster environment will be provided to interested users for the duration of the lab
- The aforementioned prerequisites have already been setup for these clusters. 

Reach out to [Udit Gaurav](udit.gaurav@mayadata.io) or [Shubham Chaudhary](shubham.chaudhary@mayadata.io)

### UseCase & Hypothesis 

The demo involves validation of the consumer timeout values upon a switch/failover in the partition leader. This is tested  by injecting transient failures on the leader broker 
pod for a topic which contains a single multi-replicated partition. The experiment creates such a topic along with a producer-consumer container pair & verifies successful message 
transmission to the consumer container

Steady State Hypothesis: All brokers (3) are alive & active. MessageQueue is alive 

### Demo Steps 

- Schedule the [kafka-broker-pod-failure](./chaos-workflow/kafka-wf.yaml) workflow from the litmus Portal (using the `upload YAML` option). To access the portal & run this workflow
refer to the [Litmus Portal User Guide](https://docs.google.com/document/d/1fiN25BrZpvqg0UkBCuqQBE7Mx8BwDGC8ss2j2oXkZNA/edit#)

- Visualize the workflow & the Prometheus/Grafana dashboards for changes to broker count & partition replicas.

- Verify the ChaosEngine & ChaosResult Statuses to know the experiment verdict post workflow completion. Sample results (including experiment pod logs & chaosresult dumps for successful & failure cases) can be found [here](./results)




