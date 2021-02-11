# Declarative Hypothesis Using Litmus Probes

- The chaos intent is now declarative, your hypothesis should be too! 
- [Litmus Probes](https://docs.litmuschaos.io/docs/chaosengine/) are means to define your steady state hypothesis in a declarative manner 
- Steady state definition can be *diverse*. Expectations around deviation/changes in the behaviour of this diverse set of steady-state behaviour makes up the hypothesis. 
  This could be: 
  - Performance. Commonly measured by prometheus metrics
  - Service availability/uptime
  - Complex conditions like data integrity
  - Nowadays, Kubernetes resource states (with all the custom resources & operators in place) 
- Hypothesis ties into SLOs, generally. 

### What We Will See In The Demo: 

- Disrupt an application deployment  by killing a replica & observe how the experiment validates the hypothesis around app latency (request_duration) & availability.
- The experiment attempts to highlight a simple deployment inefficiency
- Makes use of PromProbe & httpProbe for this purpose. 

### Demo Playbook

- Discuss the application setup & environment 
- Describe the [chaos manifest](./podtato-head-wf.yaml) instrumented with the probes
- Execute chaos: view both failure & success cases (scaled replicas) with respective artifacts. Visualize the app behaviour on the monitoring system (Grafana)


  
