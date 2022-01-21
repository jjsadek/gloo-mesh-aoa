# gloo-mesh-demo-aoa
This repo leverages the Argo CD app-of-apps pattern to demonstrate a GitOps workflow to deploy and configure a multi-cluster mesh demo
 
Spin up three clusters named `cluster1`, `cluster2`, and `mgmt`

Run:
```
./deploy.sh
```

Resource Requirements:
- This demo has been tested on 1x `n2-standard-4` (gke), `m5.xlarge` (aws), or `Standard_DS3_v2` (azure) instance for `mgmt` cluster
- This demo has been tested on 2x `n2-standard-4` (gke), `m5.xlarge` (aws), or `Standard_DS3_v2` (azure) instances for `cluster1` and `cluster2`

Note:
- A temporary (2 day currently) license key is used here for demonstration purposes
- By default, the script expects to deploy into three clusters named `mgmt`, `cluster1`, and `cluster2`. This is configurable by changing the variables in the `deploy.sh`. A check is done to ensure that the defined contexts exist before proceeding with the installation.
- Although you may change the contexts where apps are deployed as describe above, the Istio cluster names will remain stable references `cluster1` and `cluster2`

# App of Apps Explained
Each cluster in the `environments` directory contains a `meta` directory which consists of three [app-of-apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) that sync and deploy the Applications in the corresponding `apps`, `config` and `infra` directories. By using the app-of-app pattern, a Platform Administrator can provide some self-service capabilities to a user by delivering a synced directory in Git (i.e. infra team controls `infra` directory, app team to `app` directory) while still controlling what is ultimately deployed to the cluster and exposed through standard Kubernetes RBAC and Policy. (Platform Admin owns `config` directory)

(Diagram to come shortly..)