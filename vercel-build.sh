#!/bin/bash
set -e
echo "Starting Flutter Web Build..."
cd smgs_mobile
bash vercel-build.sh
