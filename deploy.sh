#!/bin/bash
cluster1_context="cluster1"
cluster2_context="cluster2"
mgmt_context="mgmt"
meshctl_version="v1.2.7"

# check to see if defined contexts exist
if [[ $(kubectl config get-contexts | grep ${mgmt_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster1_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster2_context}) == "" ]]; then
  echo "Check Failed: Either mgmt, cluster1, and cluster2 contexts do not exist. Please check to see if you have three clusters available"
  echo "Run 'kubectl config get-contexts' to see currently available contexts. If the clusters are available, please make sure that they are named correctly. Default is mgmt, cluster1, and cluster2"
  exit 1;
fi

# install argocd on mgmt, ${cluster1_context}, and ${cluster2_context}
cd argocd
./install-argocd.sh default ${mgmt_context}
./install-argocd.sh default ${cluster1_context}
./install-argocd.sh default ${cluster2_context}

# wait for argo cluster rollout
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${mgmt_context}
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${cluster2_context}

# deploy mgmt environment apps aoa
kubectl apply -f environments/mgmt/meta/meta-mgmt-env-apps.yaml --context ${mgmt_context}
# use later
#kubectl apply -f environments/mgmt/meta/meta-mgmt-env-config.yaml

# deploy cluster1 environment apps aoa
kubectl apply -f environments/cluster1/meta/meta-cluster1-env-apps.yaml
# use later
#kubectl apply -f environments/cluster1/meta/meta-cluster1-env-config.yaml

# deploy cluster2 environment apps aoa
kubectl apply -f environments/cluster2/meta/meta-cluster2-env-apps.yaml
# use later
#kubectl apply -f environments/cluster2/meta/meta-cluster2-env-config.yaml

# register clusters to gloo mesh
cd ../gloo-mesh/
./scripts/meshctl-register.sh ${mgmt_context} ${cluster1_context} ${meshctl_version}
./scripts/meshctl-register.sh ${mgmt_context} ${cluster2_context} ${meshctl_version}


# echo port-forward commands
echo
echo "access gloo mesh dashboard:"
echo "kubectl port-forward -n gloo-mesh svc/dashboard 8090 --context ${mgmt_context}"
echo 
echo "access argocd dashboard:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --context ${mgmt_context}"
echo
echo "You can use the following command to validate which cluster handles the requests:"
echo "kubectl --context ${cluster1_context} logs -l app=reviews -c istio-proxy -f"
echo "kubectl --context ${cluster2_context} logs -l app=reviews -c istio-proxy -f"
echo
echo "Continue on with bookinfo gloo-mesh-gateway lab in gitops-library git repo:"
echo "cd bookinfo/argo/config/domain/wildcard/gmg/"
echo 