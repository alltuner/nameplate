# Changelog

## [0.1.3](https://github.com/alltuner/nameplate/compare/v0.1.2...v0.1.3) (2026-04-04)


### Documentation Updates

* fix incorrect port conflict troubleshooting advice ([#12](https://github.com/alltuner/nameplate/issues/12)) ([cccbdf7](https://github.com/alltuner/nameplate/commit/cccbdf79b8068aeb79aa051a9d57f05919d849c1))
* simplify quick start with inline docker-compose example ([#10](https://github.com/alltuner/nameplate/issues/10)) ([98cffd0](https://github.com/alltuner/nameplate/commit/98cffd0c6f0ee78f1aaf2b709d6031e6d70d3904))


### CI/CD Changes

* exclude documentation paths from release-please ([#9](https://github.com/alltuner/nameplate/issues/9)) ([7a66b28](https://github.com/alltuner/nameplate/commit/7a66b281dcf434204b06806debd2a4cda868e1d4))


### Build System

* use Go cross-compilation instead of QEMU for CoreDNS builds ([#13](https://github.com/alltuner/nameplate/issues/13)) ([d9054b8](https://github.com/alltuner/nameplate/commit/d9054b89941f77e6e3ba4f35bb78b23d0dc97437))

## [0.1.2](https://github.com/alltuner/nameplate/compare/v0.1.1...v0.1.2) (2026-04-04)


### Features

* add optional upstream DNS forwarding configuration ([#6](https://github.com/alltuner/nameplate/issues/6)) ([86db675](https://github.com/alltuner/nameplate/commit/86db67564103d16dd2a2e58abfa78915ebf711bb))


### Miscellaneous Chores

* bump coredns-tailscale plugin to v0.3.22 ([#8](https://github.com/alltuner/nameplate/issues/8)) ([ef584b6](https://github.com/alltuner/nameplate/commit/ef584b6d674e57d8f889e2f12c2de4ca9615c672))

## [0.1.1](https://github.com/alltuner/nameplate/compare/v0.1.0...v0.1.1) (2026-04-04)


### Features

* add release-please and multi-arch Docker CI ([8646a04](https://github.com/alltuner/nameplate/commit/8646a04d7c733e9e2fede9444be90050236808d2))


### Build System

* split Dockerfile layers for better cache hits ([668d94c](https://github.com/alltuner/nameplate/commit/668d94cb99ee80fb4c4e335cccb7784fcae757ce))
