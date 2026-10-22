# Only replace the presentation entry point. Services, plugin, CLI and dependencies
# continue to come from the locked upstream Caelestia input.
{ upstream, design, font }:
upstream.overrideAttrs (old: {
  preFixup = (old.preFixup or "") + ''
    qtWrapperArgs+=(--set CAELESTIA_ISLAND_FONT ${font})
    qtWrapperArgs+=(--set CAELESTIA_ISLAND_FONT_FAMILY Inter)
  '';
  postPatch = (old.postPatch or "") + ''
    mkdir -p modules/island
    cp -r ${design}/. modules/island/
    cp ${../config/caelestia/overrides/Shortcuts.qml} daemons/Shortcuts.qml
    cp ${../config/caelestia/overrides/GameMode.qml} daemons/GameMode.qml
    substituteInPlace shell.qml \
      --replace-fail 'import qs.modules.drawers' 'import qs.modules.island' \
      --replace-fail '    Drawers {}' '    Island {}'
  '';
})
