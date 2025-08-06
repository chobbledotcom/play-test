#!/bin/bash
set -euo pipefail

curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
