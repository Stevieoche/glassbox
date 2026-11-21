# Copyright 2026 Glassbox Users
# SPDX-License-Identifier: Apache-2.0
#
# verify_protocol_registration_windows.ps1 — smoke-test the Glassbox custom
# URL protocol handler registry entries on Windows.
#
# The Glassbox installer registers the "glassbox" URI scheme under
# HKCU\Software\Classes\glassbox so that glassbox:// deep-links open the
# protocol handler. This script verifies that registration is correct.
#
# Usage (from an elevated or standard PowerShell prompt):
#   powershell -ExecutionPolicy Bypass -File scripts\verify_protocol_registration_windows.ps1
#
# Optional environment variable:
#   GLASSBOX_BINARY   Full path to the glassbox binary. When set, the script
#                     checks that the protocol handler command references this
#                     binary. Mirrors the GLASSBOX_BINARY variable used by the
#                     Linux and macOS equivalents of this script.
#
# Exit codes:
#   0   Registration verified successfully.
#   1   A required registry key, value, or command reference is missing.

$ErrorActionPreference = 'Stop'

$registryPath = 'Registry::HKEY_CURRENT_USER\Software\Classes\glassbox'
$commandPath  = 'Registry::HKEY_CURRENT_USER\Software\Classes\glassbox\shell\open\command'

if (-not (Test-Path $registryPath)) {
    throw "Missing protocol registry key: $registryPath"
}

if (-not (Test-Path $commandPath)) {
    throw "Missing protocol open command key: $commandPath"
}

$rootKey     = Get-Item $registryPath
$urlProtocol = $rootKey.GetValue('URL Protocol', $null)
if ($null -eq $urlProtocol) {
    throw 'Missing URL Protocol registry value'
}

$commandKey = Get-Item $commandPath
$command    = $commandKey.GetValue('')
if ([string]::IsNullOrWhiteSpace($command)) {
    throw 'Missing default protocol open command'
}

if ($env:GLASSBOX_BINARY) {
    # Normalize paths to use forward slashes for cross-tool comparison.
    $normalizedCommand = $command.Replace('\', '/')
    $normalizedBinary  = $env:GLASSBOX_BINARY.Replace('\', '/')

    if ($normalizedCommand -notlike "*$normalizedBinary*") {
        throw "Protocol command does not reference expected binary: $normalizedBinary (got $normalizedCommand)"
    }
}

if ($command -notlike '*protocol-handler*') {
    throw 'Protocol command does not invoke protocol-handler'
}

Write-Host 'Windows protocol registration verified'
