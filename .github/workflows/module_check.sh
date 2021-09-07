#!/bin/bash
if [[ "$(grep ^module main.tf | wc -l)" == "2" ]]; then
  echo "Everything looks good!"
  exit 0
else
  echo "You have forgotten to comment out non-free modules!"
  grep ^module main.tf
  exit 1
fi