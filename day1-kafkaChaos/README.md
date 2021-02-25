# Kafka Broker Pod Failure Chaos Workflow 


### PreRequisites 

**NOTE*: _Only needed if you are doing this demo on your own cluster, i.e., setting up the demo env from scratch. Not needed if you have a pre-packaged environment provided by litmus bootcamp organizers) _

- Install Kafka Cluster on Kubernetes (the demo uses [KUDO](https://kudo.dev/docs/runbooks/kafka/install.html#installing-the-operator) to install this)
- Install the Litmus (Portal) Control Plane. You can use the step provided in the [Portal Documentation](https://github.com/litmuschaos/litmus/tree/master/litmus-portal#applying-k8s-manifest)
- Setup the [Kafka](./kafka-exporter-helm) (via helm) & [LitmusChaos](./chaos-exporter) prometheus exporters
- Setup the ServiceMonitors for [Kafka](./service-monitors/kafka-exporter-service-monitor.yaml) & [LitmusChaos](./service-monitors/chaos-exporter-service-monitor.yaml) prometheus exporters
- Setup the Prometheus monitoring infra via the [Prometheus Operator](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-operator) with suitable [Configuration](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-configuration)
- Apply the [Prometheus CR](./prometheus/prometheus.yaml) to scrape metrics from the Kafka & LitmusChaos exporters
- (Optional) Setup [Grafana](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/grafana) to view the Kafka & LitmusChaos metrics. This [sample](./grafana/kafka-jmx.json) dashboard JSON can be used.

**NOTE**

- The ChaosCarnival bootcamp has an optional lab session for which a prepackaged cluster environment will be provided to interested users for the duration of the lab
- The aforementioned prerequisites have already been setup for these clusters. 

Reach out to [Udit Gaurav](udit.gaurav@mayadata.io) or [Shubham Chaudhary](shubham.chaudhary@mayadata.io) for on-demand lab sessions. 

## UseCase & Hypothesis 

The demo involves using Litmus to inject chaos on a Kafka statefulset to hypothesize & arrive upon the correct value for a deployment attribute (message timeout on kafka consumer) for a given cluster environment (3 kafka brokers using default/standard storage class), at the same time observing & validating some critical kafka metrics. More details on what the scenario entails is provided below: 

- The experiment begins by generating load on the Kafka cluster via a test producer/consumer pair, the consumer being configured with a _desired_ message timeout. The message stream in itself is very simple and just prints a timestamped string. It consists of a single topic with just a single partition, replicated across the 3 brokers. 

  ![image](https://user-images.githubusercontent.com/21166217/109115336-efe30680-7764-11eb-90c3-016890e923f7.png)

- The partition leader amongst the kafka brokers is identified (via kafka client) and killed, triggering a failover resulting in a new partition leader. It is possible that the broker pod that is targeted for failure happens to be the "Controller Broker" (also called "Active Controller") that facilitates the failovers for partition leaders and speaks to zookeeper et al. In such a case, a new active controller is elected. All of which can contribute to data transfer being stalled for a while. The timne taken for this may depend upon the infrastructure. 

  ![image](https://user-images.githubusercontent.com/21166217/109115795-9202ee80-7765-11eb-9f2d-67fbeafdc16f.png)

- The chosen message timeout may be good enough to tolerate this disruption in data traffic OR might be insufficient, resulting in a broken message stream on the consumer. 

  ![image](https://user-images.githubusercontent.com/21166217/109116891-3d607300-7767-11eb-9046-29589336cbe2.png)
  
  It is expected to play around with the timeout values (specified as an [ENV variable](https://github.com/chaoscarnival/bootcamps/blob/90d5e3e17194ed8effa1f290e52602c173a52c45/day1-kafkaChaos/chaos-workflow/kafka-wf-probe.yaml#L104) in the Chaos Workflow spec to arrive at an eventual value that succeeds. 

- In addition to the core constraint of an unbroken message stream, the experiment also factors in other important considerations around application behaviour. In this experiment, we also expect that despite chaos, there should be no : 

  - OfflinePartitions (unavailable data-stores) throught the procedure 
  - UnderReplicated Partitions (we use 3 replicas by default) before beginning the experiment (to avoid running chaos on a degaded setup) & once the chaos ceases/ends (acts as a check to see if all brokers are back to optimal state)

  ![image](https://user-images.githubusercontent.com/21166217/109117980-b6ac9580-7768-11eb-94db-502ee4ff92ad.png)

  This is ensured by setting up the right litmus [Probes](https://docs.litmuschaos.io/docs/litmus-probe/)

  ![image](https://user-images.githubusercontent.com/21166217/109118845-dc866a00-7769-11eb-9e52-40c6e089594f.png)


## Demo Steps 

(To learn more about using the portal please
refer to the [Litmus Portal User Guide](https://docs.google.com/document/d/1fiN25BrZpvqg0UkBCuqQBE7Mx8BwDGC8ss2j2oXkZNA/edit#))

- Login to the Litmus portal with the right credentials

  ![image](https://user-images.githubusercontent.com/21166217/109124301-c62fdc80-7770-11eb-94c8-a2fba299d7b8.png)

- Schedule the [kafka-broker-pod-failure](./chaos-workflow/kafka-wf-probe.yaml) workflow from the litmus Portal (using the `upload YAML` option). 

  ![image](https://user-images.githubusercontent.com/21166217/109124549-10b15900-7771-11eb-8a04-ba706f2d29e0.png)
  
  ![image](https://user-images.githubusercontent.com/21166217/109124732-45bdab80-7771-11eb-9d44-52bd7ccf071a.png)
  
  ![image](https://user-images.githubusercontent.com/21166217/109124921-7998d100-7771-11eb-96cd-605c8dd61966.png)
  
  ![image](https://user-images.githubusercontent.com/21166217/109125010-933a1880-7771-11eb-83b9-7245e20a0e54.png)
  
  ![image](https://user-images.githubusercontent.com/21166217/109125105-ae0c8d00-7771-11eb-9256-b5fd99e83869.png)
  
  ![image](https://user-images.githubusercontent.com/21166217/109125181-c2e92080-7771-11eb-9bb8-59b4de29efc7.png)

- Visualize the workflow progress from the Litmus Portal

  ![image](https://user-images.githubusercontent.com/21166217/109125289-e4e2a300-7771-11eb-8080-7feb8583ff56.png)
  
- Observe app statistics in the Grafana dashboard during active chaos period. 

  ![image](https://user-images.githubusercontent.com/21166217/109116687-f4a8ba00-7766-11eb-9149-26ef50066d83.png)
  

- Verify the ChaosEngine & ChaosResult Statuses to know the experiment verdict post workflow completion. Sample results (including experiment pod logs & chaosresult dumps for successful & failure cases) can be found [here](./results)




