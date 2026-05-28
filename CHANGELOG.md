# Changelog

## [0.1.7](https://github.com/alltuner/nameplate/compare/v0.1.6...v0.1.7) (2026-05-04)


### Miscellaneous Chores

* **deps:** update googleapis/release-please-action action to v5 ([#35](https://github.com/alltuner/nameplate/issues/35)) ([0bea0cb](https://github.com/alltuner/nameplate/commit/0bea0cbc3f875dbfade2081e2d5e3a85a189cee5))


### Documentation Updates

* standardize README to alltuner brand structure ([#40](https://github.com/alltuner/nameplate/issues/40)) ([16816be](https://github.com/alltuner/nameplate/commit/16816be074460177bb0d4a06c02ae772db39e61d))


### CI/CD Changes

* allow revert as a conventional PR title type ([#39](https://github.com/alltuner/nameplate/issues/39)) ([bab5ff5](https://github.com/alltuner/nameplate/commit/bab5ff53e7f6ea607f1be00eb5a5e1d31354dfe8))
* validate PR titles as conventional commits ([#37](https://github.com/alltuner/nameplate/issues/37)) ([ec1404d](https://github.com/alltuner/nameplate/commit/ec1404d0819b77c3f7c1ba24f2c403bfeb27140a))

## [0.1.6](https://github.com/alltuner/nameplate/compare/v0.1.5...v0.1.6) (2026-04-05)


### Documentation Updates

* clarify CoreDNS version is tied to plugin.cfg ([#30](https://github.com/alltuner/nameplate/issues/30)) ([dfd5a18](https://github.com/alltuner/nameplate/commit/dfd5a18c1ce4bd1bedef824738eac7babdaa6f2b)), closes [#22](https://github.com/alltuner/nameplate/issues/22)


### CI/CD Changes

* add Docker build validation on PRs and main pushes ([#26](https://github.com/alltuner/nameplate/issues/26)) ([7c0e2be](https://github.com/alltuner/nameplate/commit/7c0e2bed7d1c4ddba1a3e90e73c427ad46516a5c)), closes [#21](https://github.com/alltuner/nameplate/issues/21)
* pin third-party GitHub Actions by commit SHA ([#29](https://github.com/alltuner/nameplate/issues/29)) ([33c9f39](https://github.com/alltuner/nameplate/commit/33c9f394c2a5bc615d0b79d188cccefdb0a3e1b9)), closes [#25](https://github.com/alltuner/nameplate/issues/25)


### Build System

* pin Docker base images by digest for reproducible builds ([#27](https://github.com/alltuner/nameplate/issues/27)) ([ac4e17e](https://github.com/alltuner/nameplate/commit/ac4e17ea4571507a19f6eb58d838216dd0ad3112)), closes [#24](https://github.com/alltuner/nameplate/issues/24)
* trim plugin.cfg to only plugins used in Corefile ([#28](https://github.com/alltuner/nameplate/issues/28)) ([290a5e6](https://github.com/alltuner/nameplate/commit/290a5e619420d68592e32bdc6a4d38dd81d7f6ec)), closes [#23](https://github.com/alltuner/nameplate/issues/23)

## [0.1.5](https://github.com/alltuner/nameplate/compare/v0.1.4...v0.1.5) (2026-04-04)


### Build System

* simplify Dockerfile with checked-in plugin.cfg and source tarball ([#18](https://github.com/alltuner/nameplate/issues/18)) ([bc972a4](https://github.com/alltuner/nameplate/commit/bc972a4c6e69c58876293d7c3628434560601a9d))

## [0.1.4](https://github.com/alltuner/nameplate/compare/v0.1.3...v0.1.4) (2026-04-04)


### Miscellaneous Chores

* **deps:** update actions/checkout action to v6 ([#17](https://github.com/alltuner/nameplate/issues/17)) ([f640a78](https://github.com/alltuner/nameplate/commit/f640a78221f1b1ef5ef593886bb31bb65a0db2ab))


### CI/CD Changes

* Add Claude Code GitHub Workflow ([#14](https://github.com/alltuner/nameplate/issues/14)) ([0ba5944](https://github.com/alltuner/nameplate/commit/0ba59442450f645d493e758c296493b5c4351e9e))


### Build System

* remove gettext dependency and QEMU from CI ([#15](https://github.com/alltuner/nameplate/issues/15)) ([392a02e](https://github.com/alltuner/nameplate/commit/392a02ebe1512e4f6577438d386f56991407f639))

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
