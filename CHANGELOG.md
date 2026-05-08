# Changelog

## [1.6.0](https://github.com/cuongtranba/skill-stack/compare/v1.5.3...v1.6.0) (2026-05-08)


### Features

* add /stack command router ([9125bae](https://github.com/cuongtranba/skill-stack/commit/9125baefcbd120b0cfd7de62afec1f6570e9a5f6))
* add plugin manifests ([b276453](https://github.com/cuongtranba/skill-stack/commit/b276453bdf162746615fef04d3bc12875e69883e))
* add stack agent orchestrator ([a7fbd3c](https://github.com/cuongtranba/skill-stack/commit/a7fbd3ce509f62bf17156c864cb469476fa8e7eb))
* add stack-build skill with Socratic flow ([beb244b](https://github.com/cuongtranba/skill-stack/commit/beb244be3973129351a68f37c96056df35745009))
* add stack-run execution engine skill ([3779f6e](https://github.com/cuongtranba/skill-stack/commit/3779f6e065a08127be74d3a6fc1bb87c9ed9eda7))
* add stack-validate skill with conversational fixes ([b1912f3](https://github.com/cuongtranba/skill-stack/commit/b1912f38e451e3e138023af43fa625783e120a2f))
* **dev-verify:** add development completion verification skill ([4e2a21d](https://github.com/cuongtranba/skill-stack/commit/4e2a21d013ec135b1dea752f49e7c5054672df9c))
* **dokploy:** add deployment skill with config-driven API access ([a13fd0f](https://github.com/cuongtranba/skill-stack/commit/a13fd0fc57020f856b6fadaf38b03844ba2ffba0))
* **dokploy:** add golden rule - API for changes, SSH for verification only ([7812f79](https://github.com/cuongtranba/skill-stack/commit/7812f79c5c23f5614dc8a1f056439de9f575c9d7))
* **dokploy:** add username/password auth and on-demand Swagger discovery ([81078e9](https://github.com/cuongtranba/skill-stack/commit/81078e99621f0c1460c16238f7b59dc759afa1ee))
* **golang:** add /go:audit, /go:fix, /go:verify slash commands ([fed8f50](https://github.com/cuongtranba/skill-stack/commit/fed8f50137c5e40b683d9951b28f16d9eddc211b))
* **golang:** add Go best practices skill with audit/fix/verify commands ([5c313fe](https://github.com/cuongtranba/skill-stack/commit/5c313fe460c7fc4d67548469a6eaed105b747210))
* **stack-build:** add custom skill/command creation when no match ([085068f](https://github.com/cuongtranba/skill-stack/commit/085068f56f035c31e464873251363e3c85cbf179))
* **stack-build:** add intelligent skill suggestion mapping ([897b4d9](https://github.com/cuongtranba/skill-stack/commit/897b4d9e52c8168b50bc3d890da37dffd775c4f4))
* **stack-build:** require location confirmation before saving ([2d8e00c](https://github.com/cuongtranba/skill-stack/commit/2d8e00c53dcee76ab1503b06002fbb27086a685a))
* **test-quality-verify:** add test quality verification skill ([b1917b7](https://github.com/cuongtranba/skill-stack/commit/b1917b78e2faa2f3cb9b599895b1728152c52293))
* use /skills command for skill discovery ([df4cb81](https://github.com/cuongtranba/skill-stack/commit/df4cb81849ce4229f03bf35d82390e575d4c402d))
* **wcag-verify:** add color contrast analysis section ([6addfec](https://github.com/cuongtranba/skill-stack/commit/6addfec285f0ece10a66c599a19b6fb4731af6ac))
* **wcag-verify:** add critical automated checks (1.1.1, 1.3.1, 2.1.1, 4.1.2) ([e77936a](https://github.com/cuongtranba/skill-stack/commit/e77936a6d341169ded3e4552e14231132c4d4942))
* **wcag-verify:** add fix flow section ([003f7c9](https://github.com/cuongtranba/skill-stack/commit/003f7c943f2cd2f5883b27814bb7073cb3bf4719))
* **wcag-verify:** add guidelines and WCAG reference ([f5c6be8](https://github.com/cuongtranba/skill-stack/commit/f5c6be808438232b20c364ccc6fdc9f683cb3fe8))
* **wcag-verify:** add major automated checks (1.4.3, 1.4.11, 2.4.4, 1.3.5, 2.5.3) ([346611d](https://github.com/cuongtranba/skill-stack/commit/346611dc44f8792fbbc1cc3f892a808b5069658a))
* **wcag-verify:** add manual review checklist section ([62975bd](https://github.com/cuongtranba/skill-stack/commit/62975bd80874c42ed03bc71cbe0a3fe6bba302e8))
* **wcag-verify:** add minor automated checks (1.4.4, 2.4.6, 1.4.10) ([4ed8934](https://github.com/cuongtranba/skill-stack/commit/4ed8934a10dcaedf567ffce18f46d9ad81b8c5c2))
* **wcag-verify:** add output format section ([27944f0](https://github.com/cuongtranba/skill-stack/commit/27944f0278ff5ca4d2bbd377bf0b9bb80c7328ac))
* **wcag-verify:** add scope detection section ([62d8032](https://github.com/cuongtranba/skill-stack/commit/62d803286f239eee734a779f1077fa3b4d68efb0))
* **wcag-verify:** add state-based contrast checking ([90d9aa0](https://github.com/cuongtranba/skill-stack/commit/90d9aa0f577794c77158273006228d46dc5796f1))
* **wcag-verify:** auto-trigger on frontend code generation ([0f4a7dc](https://github.com/cuongtranba/skill-stack/commit/0f4a7dcabf65e146b1fc6a86313d751fc8fdfa16))
* **wcag-verify:** create skill with frontmatter and overview ([ddabf84](https://github.com/cuongtranba/skill-stack/commit/ddabf846e14d2b59dfe29f6851a36e7627c73374))


### Bug Fixes

* address workflow review issues and add configuration support ([0bf704c](https://github.com/cuongtranba/skill-stack/commit/0bf704c1b32a7f61609cda3e76b636146c8db267))
* **dokploy:** use dynamic OpenAPI discovery instead of hardcoded endpoints ([28afe09](https://github.com/cuongtranba/skill-stack/commit/28afe09e6e0144305a7699db5aff34da2afcfb3d))
* **golang:** harden H02 bare `return err` rule ([#1](https://github.com/cuongtranba/skill-stack/issues/1)) ([919797f](https://github.com/cuongtranba/skill-stack/commit/919797f15e009e4dd26b10cb3951093df72cbab4))
* move golang skill to skills/ directory for consistency ([4cf1891](https://github.com/cuongtranba/skill-stack/commit/4cf18919c9b0eb3898c77cafe42b5764db72b920))
* **stack-build:** save custom skills/commands to local repository ([3c36091](https://github.com/cuongtranba/skill-stack/commit/3c36091670225f43998da9e7321c8871649b4775))
