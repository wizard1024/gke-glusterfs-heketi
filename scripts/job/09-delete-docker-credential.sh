#!/bin/sh

# ----------------------- [START] Delete docker registry credential ------------------------ #
kubectl -n glusterfs-heketi-bootstrap delete secret rtc-regcred
# ------------------------ [END] Delete docker registry credential ------------------------- #
