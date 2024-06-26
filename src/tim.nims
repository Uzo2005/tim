--mm:arc
--define:timHotCode
--threads:on

when defined napibuild:
  --define:napiOrWasm
  --define:watchoutBrowserSync
  --noMain:on
  --passC:"-I/usr/include/node -I/usr/local/include/node"

when isMainModule:
  --define:timStandalone
  when defined release:
    --opt:speed
    --define:useMalloc
    --define:danger
    --checks:off
    --passC:"-flto"
    --passL:"-flto"
    --define:nimAllocPagesViaMalloc