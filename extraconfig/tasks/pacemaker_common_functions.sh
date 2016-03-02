#!/bin/bash

set -eu

function check_resource {

  if [ "$#" -ne 3 ]; then
      echo_error "ERROR: check_resource function expects 3 parameters, $# given"
      exit 1
  fi

  service=$1
  state=$2
  timeout=$3

  if [ "$state" = "stopped" ]; then
      match_for_incomplete='Started'
  else # started
      match_for_incomplete='Stopped'
  fi

  if timeout -k 10 $timeout crm_resource --wait; then
      node_states=$(pcs status --full | grep "$service" | grep -v Clone)
      if echo "$node_states" | grep -q "$match_for_incomplete"; then
          echo_error "ERROR: cluster finished transition but $service was not in $state state, exiting."
          exit 1
      else
        echo "$service has $state"
      fi
  else
      echo_error "ERROR: cluster remained unstable for more than $timeout seconds, exiting."
      exit 1
  fi

}

function echo_error {
    echo "$@" | tee /dev/fd2
}

function systemctl_swift {
    action=$1
    for S in openstack-swift-account-auditor openstack-swift-account-reaper openstack-swift-account-replicator openstack-swift-account \
             openstack-swift-container-auditor openstack-swift-container-replicator openstack-swift-container-updater openstack-swift-container \
             openstack-swift-object-auditor openstack-swift-object-replicator openstack-swift-object-updater openstack-swift-object openstack-swift-proxy; do
                systemctl $action $S
    done
}
