#!/bin/bash
set -e
echo "Starting SMGS Web Portal Build (React + Vite)..."
cd smgs_web
npm install
npm run build
echo "Build completed successfully in smgs_web/dist"
