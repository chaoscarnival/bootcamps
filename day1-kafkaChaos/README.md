# Kafka Broker Pod Failure Chaos Workflow 

### PreRequisites 

**NOTE**: _Only needed if you are doing this demo on your own cluster, i.e., setting up the demo env from scratch._

- Install Kafka Cluster on Kubernetes (the demo uses [KUDO](https://kudo.dev/docs/runbooks/kafka/install.html#installing-the-operator) to install this)
- Install the Litmus (Portal) Control Plane. You can use the step provided in the [Portal Documentation](https://litmusdocs-beta.netlify.app/docs/introduction)
- Setup the [Kafka](./kafka-exporter-helm) (via helm) & [LitmusChaos](https://github.com/litmuschaos/litmus/blob/master/monitoring/utils/metrics-exporters-with-service-monitors/litmus-metrics/chaos-exporter/chaos-exporter.yaml) (it is optional and comes with portal installation) prometheus exporters.
- Setup the ServiceMonitors for [Kafka](./service-monitors/kafka-exporter-service-monitor.yaml) & [LitmusChaos](./service-monitors/chaos-exporter-service-monitor.yaml) prometheus exporters
- Setup the Prometheus monitoring infra via the [Prometheus Operator](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-operator) with suitable [Configuration](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/prometheus/prometheus-configuration)
- Apply the [Prometheus CR](./prometheus/prometheus.yaml) to scrape metrics from the Kafka & LitmusChaos exporters
- (Optional) Setup [Grafana](https://github.com/litmuschaos/litmus/tree/master/monitoring/utils/grafana) to view the Kafka & LitmusChaos metrics. This [sample](./grafana/kafka-jmx.json) dashboard JSON can be used.

**NOTE**

- _The ChaosCarnival bootcamp has an optional lab session for which a prepackaged cluster environment will be provided to interested users for the duration of the lab_
- _The aforementioned prerequisites have already been setup for these clusters_
- _Reach out to [Udit Gaurav](https://github.com/uditgaurav) or [Shubham Chaudhary](https://github.com/ispeakc0de) for on-demand lab sessions_

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

  - **OfflinePartitions** (unavailable data-stores) throught the procedure 
  - **UnderReplicatedPartitions** (we use 3 replicas by default) before beginning the experiment (to avoid running chaos on a degaded setup) & once the chaos ceases/ends (acts as a check to see if all brokers are back to optimal state)

  ![image](https://user-images.githubusercontent.com/21166217/109117980-b6ac9580-7768-11eb-94db-502ee4ff92ad.png)
  
  courtesy: [Key Kafka Metrics to Monitor](https://sematext.com/blog/kafka-metrics-to-monitor/#:~:text=Offline%20partitions%20represent%20data%20stores,to%20reassign%20partitions%20when%20needed.)

- This is ensured by setting up the right litmus [Probes](https://docs.litmuschaos.io/docs/litmus-probe/)

  ![image](https://user-images.githubusercontent.com/21166217/109118845-dc866a00-7769-11eb-9e52-40c6e089594f.png)


## Demo Steps 

**NOTE**: To learn more about litmus portal setup and useage
refer to the [Litmus Portal Docs](https://litmusdocs-beta.netlify.app/docs)

- Login to the Litmus portal with the right credentials

  ![image](https://user-images.githubusercontent.com/35391335/119504017-31e20f80-bd89-11eb-8a80-58c6101c0d17.png)

- Schedule the [kafka-broker-pod-failure](./chaos-workflow/kafka-wf-probe.yaml) workflow from the litmus Portal (using the `upload YAML` option). 

  ![image](https://user-images.githubusercontent.com/35391335/119504282-72da2400-bd89-11eb-84eb-05c5c97ae82d.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504383-88e7e480-bd89-11eb-9889-0ad45cf94d01.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504479-a2892c00-bd89-11eb-994b-6ddad678eda9.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504666-d2d0ca80-bd89-11eb-8fa0-96330219d365.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504672-d49a8e00-bd89-11eb-91e8-7888c79b76a5.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504680-d6645180-bd89-11eb-8cfc-8917bcce96cc.png)
  
  ![image](https://user-images.githubusercontent.com/35391335/119504693-d7957e80-bd89-11eb-989b-0b85c6b9f4af.png)

  ![image](https://user-images.githubusercontent.com/35391335/119504699-d95f4200-bd89-11eb-915b-47c2515d9629.png)
  
  ![image](https://user-images.githubusercontent.com/35391335/119504709-db290580-bd89-11eb-9967-204a8fd74eda.png)

- Visualize the workflow progress from the Litmus Portal

  ![image](https://user-images.githubusercontent.com/35391335/119505232-60141f00-bd8a-11eb-973a-4264893f82b3.png)

- Observe app statistics in the Grafana dashboard during active chaos period. 

  ![image](https://user-images.githubusercontent.com/21166217/109116687-f4a8ba00-7766-11eb-9149-26ef50066d83.png)

- Verify the ChaosEngine & ChaosResult Statuses to know the experiment verdict post workflow completion. Sample results (including experiment pod logs & chaosresult dumps for successful & failure cases) can be found **[here](./results)**




