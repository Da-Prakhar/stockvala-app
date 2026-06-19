#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup_ios_schemes.sh  —  Create Xcode schemes for each brand flavor
#
# Run this ONCE after cloning to wire up iOS per-brand schemes.
# After running, open ios/Runner.xcworkspace → Product → Scheme to see them.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
cd "$(dirname "$0")/.."

SCHEMES_DIR="ios/Runner.xcodeproj/xcshareddata/xcschemes"
mkdir -p "$SCHEMES_DIR"

declare -A BUNDLE_IDS=(
  [stockvala]="com.stockvala.app"
  [alphatrade]="com.alphatrade.app"
  [goldfx]="com.goldfx.app"
  [nexustrade]="com.nexustrade.app"
)

declare -A APP_NAMES=(
  [stockvala]="StockVala"
  [alphatrade]="AlphaTrade"
  [goldfx]="GoldFX"
  [nexustrade]="NexusTrade"
)

for brand in stockvala alphatrade goldfx nexustrade; do
  SCHEME_FILE="$SCHEMES_DIR/${brand}.xcscheme"
  cat > "$SCHEME_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "97C146ED1CF9000F007C117D"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BRAND"
            value = "${brand}"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

  echo "Created scheme: $SCHEME_FILE"
done

echo ""
echo "Done! Open ios/Runner.xcworkspace in Xcode and select a brand scheme."
echo "Then set the bundle ID per scheme in Target → Signing & Capabilities:"
for brand in stockvala alphatrade goldfx nexustrade; do
  echo "  $brand  →  ${BUNDLE_IDS[$brand]}"
done
