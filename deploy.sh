#!/bin/bash
set -e

# note that the character '_' is an invalid value if you are replacing the defaults below
cluster1_context="cluster1"
cluster2_context="cluster2"
mgmt_context="mgmt"
gloo_mesh_version="1.2.9"

# check to see if defined contexts exist
if [[ $(kubectl config get-contexts | grep ${mgmt_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster1_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster2_context}) == "" ]]; then
  echo "Check Failed: Either mgmt, cluster1, and cluster2 contexts do not exist. Please check to see if you have three clusters available"
  echo "Run 'kubectl config get-contexts' to see currently available contexts. If the clusters are available, please make sure that they are named correctly. Default is mgmt, cluster1, and cluster2"
  exit 1;
fi

# install argocd on ${mgmt_context}, ${cluster1_context}, and ${cluster2_context}
cd argocd
./install-argocd.sh default ${mgmt_context}
./install-argocd.sh default ${cluster1_context}
./install-argocd.sh default ${cluster2_context}
cd ..

# wait for argo cluster rollout
./tools/wait-for-rollout.sh deployment argocd-server argocd 20 ${mgmt_context}
./tools/wait-for-rollout.sh deployment argocd-server argocd 20 ${cluster1_context}
./tools/wait-for-rollout.sh deployment argocd-server argocd 20 ${cluster2_context}

# deploy mgmt, cluster1, and cluster2 environment infra app-of-apps
kubectl apply -f environments/mgmt/meta/mgmt-env-infra.yaml --context ${mgmt_context}
kubectl apply -f environments/cluster1/meta/cluster1-env-infra.yaml --context ${cluster1_context}
kubectl apply -f environments/cluster2/meta/cluster2-env-infra.yaml --context ${cluster2_context}

# wait for completion of istio install
./tools/wait-for-rollout.sh deployment istiod istio-system 10 ${cluster1_context}
./tools/wait-for-rollout.sh deployment istiod istio-system 10 ${cluster2_context}

# register clusters to gloo mesh
./tools/meshctl-register-helm-argocd.sh ${mgmt_context} ${cluster1_context} ${cluster2_context} ${gloo_mesh_version}

# deploy cluster1, and cluster2 environment apps aoa
#kubectl apply -f mgmt/mgmt-env-apps.yaml --context ${mgmt_context}
kubectl apply -f environments/cluster1/meta/cluster1-env-apps.yaml --context ${cluster1_context}
kubectl apply -f environments/cluster2/meta/cluster2-env-apps.yaml --context ${cluster2_context}

# wait for completion of bookinfo install
./tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster1_context}
./tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster2_context}

# deploy mgmt, cluster1, and cluster2 environment config aoa
kubectl apply -f environments/mgmt/meta/mgmt-env-config.yaml --context ${mgmt_context}
#kubectl apply -f cluster1/meta/cluster1-env-apps.yaml --context ${cluster1_context}
#kubectl apply -f cluster2/meta/cluster2-env-apps.yaml --context ${cluster2_context}

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