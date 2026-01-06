#!/bin/bash
# Script to open Xcode for device pairing

echo "Opening Xcode workspace..."
open ios/Runner.xcworkspace

echo ""
echo "=========================================="
echo "DEVICE PAIRING INSTRUCTIONS"
echo "=========================================="
echo ""
echo "1. In Xcode, go to: Window → Devices and Simulators (⇧⌘2)"
echo "2. Find 'Linas's iPhone' in the left sidebar"
echo "3. Click on it and click 'Use for Development' if unpaired"
echo "4. On your iPhone, tap 'Trust This Computer' when prompted"
echo "5. Enter your iPhone passcode"
echo "6. Wait for pairing to complete (green indicator)"
echo ""
echo "After pairing, verify with: flutter devices"
echo ""
