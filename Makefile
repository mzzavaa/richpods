# RichPods (Incredible fork) — local development.
#
#   make setup     one-time: fonts + dependencies + shared build
#   make dev       run everything (proxy + player + editor + website)
#   make check     type-check, tests, audit
#   make stop      free the ports if something is left running
#
# Ports: proxy 4000 · website 3000 · player 5173 · editor 5174

.PHONY: setup fonts install dev dev-demo emulators server grant-admin \
        proxy player editor website build check test audit typecheck stop clean help

# corepack ships with Node but is not on PATH on this machine, so every pnpm
# call goes through it explicitly. COREPACK_ENABLE_DOWNLOAD_PROMPT=0 stops it
# blocking on "download pnpm@11.5.1?" the first time.
# Only prepended when it exists, so this Makefile still works on a machine
# where corepack is already on PATH (CI, another contributor).
NODE_BIN := $(HOME)/.local/lib/node/bin
export PATH := $(if $(wildcard $(NODE_BIN)),$(NODE_BIN):,)$(PATH)
export COREPACK_ENABLE_DOWNLOAD_PROMPT := 0
# Absolute path, not bare "pnpm": make runs single-command recipes directly
# without a shell, and that bypasses the PATH exported above. Recipes with
# shell metacharacters were fine; `make audit` was not.
PNPM := $(if $(wildcard $(NODE_BIN)/pnpm),$(NODE_BIN)/pnpm,pnpm)

# Homebrew's openjdk is keg-only, so it is not on PATH by default and the
# Firebase emulators are Java. Resolved lazily; harmless if absent.
JAVA_BIN := $(shell brew --prefix openjdk 2>/dev/null)/bin
export PATH := $(if $(wildcard $(JAVA_BIN)),$(JAVA_BIN):,)$(PATH)

# Ports are pinned explicitly and strictly. Both dev scripts are bare `vite`,
# which defaults to 5173, so whichever started first used to win the port and
# the other silently landed on 5174. `exec vite` is used rather than
# `run dev -- --port`, because pnpm forwards the `--` to vite, which then
# treats it as an argument terminator and ignores the port entirely.
PLAYER_DEV := $(PNPM) --filter @richpods/player exec vite --port 5173 --strictPort
EDITOR_DEV := $(PNPM) --filter @richpods/editor exec vite --port 5174 --strictPort

FIREBASE := $(PNPM) --filter @richpods/server exec firebase
PROJECT  := demo-incredible-podcasts

FONT_DIR := shared/assets/fonts
CDN      := https://cdn.jsdelivr.net/npm

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n", $$1, $$2}'

setup: fonts install ## One-time setup: fonts, dependencies, shared build
	@echo "-> setup complete. now run: make dev"

# Upstream deliberately ships no font binaries, and the build HARD FAILS with a
# postcss ENOENT if they are missing. All eight are SIL OFL.
fonts: ## Download the OFL fonts the build requires
	@mkdir -p $(FONT_DIR)
	@echo "-> fonts"
	@test -f "$(FONT_DIR)/OpenSans-VariableFont_wdth,wght.ttf" || curl -sSLf -o "$(FONT_DIR)/OpenSans-VariableFont_wdth,wght.ttf" \
	  "https://raw.githubusercontent.com/google/fonts/main/ofl/opensans/OpenSans%5Bwdth%2Cwght%5D.ttf"
	@test -f "$(FONT_DIR)/OpenSans-Italic-VariableFont_wdth,wght.ttf" || curl -sSLf -o "$(FONT_DIR)/OpenSans-Italic-VariableFont_wdth,wght.ttf" \
	  "https://raw.githubusercontent.com/google/fonts/main/ofl/opensans/OpenSans-Italic%5Bwdth%2Cwght%5D.ttf"
	@test -f "$(FONT_DIR)/JetBrainsMono[wght].woff2" || curl -sSLf -o "$(FONT_DIR)/JetBrainsMono[wght].woff2" \
	  "$(CDN)/@fontsource-variable/jetbrains-mono/files/jetbrains-mono-latin-wght-normal.woff2"
	@test -f "$(FONT_DIR)/JetBrainsMono-Italic[wght].woff2" || curl -sSLf -o "$(FONT_DIR)/JetBrainsMono-Italic[wght].woff2" \
	  "$(CDN)/@fontsource-variable/jetbrains-mono/files/jetbrains-mono-latin-wght-italic.woff2"
	@test -f "$(FONT_DIR)/Inter[wght].woff2" || curl -sSLf -o "$(FONT_DIR)/Inter[wght].woff2" \
	  "$(CDN)/@fontsource-variable/inter/files/inter-latin-wght-normal.woff2"
	@test -f "$(FONT_DIR)/Inter-Italic[wght].woff2" || curl -sSLf -o "$(FONT_DIR)/Inter-Italic[wght].woff2" \
	  "$(CDN)/@fontsource-variable/inter/files/inter-latin-wght-italic.woff2"
	@test -f "$(FONT_DIR)/Newsreader[wght].woff2" || curl -sSLf -o "$(FONT_DIR)/Newsreader[wght].woff2" \
	  "$(CDN)/@fontsource-variable/newsreader/files/newsreader-latin-wght-normal.woff2"
	@test -f "$(FONT_DIR)/IBMPlexMono-400.woff2" || curl -sSLf -o "$(FONT_DIR)/IBMPlexMono-400.woff2" \
	  "$(CDN)/@fontsource/ibm-plex-mono/files/ibm-plex-mono-latin-400-normal.woff2"
	@test -f "$(FONT_DIR)/IBMPlexMono-600.woff2" || curl -sSLf -o "$(FONT_DIR)/IBMPlexMono-600.woff2" \
	  "$(CDN)/@fontsource/ibm-plex-mono/files/ibm-plex-mono-latin-600-normal.woff2"
	@# Playfair Display is still referenced by upstream's base.scss.
	@test -f "$(FONT_DIR)/playfair-display-v37-latin_latin-ext-regular.woff2" || { \
	  tmp=$$(mktemp -d); \
	  curl -sSLf -o $$tmp/pf.zip "https://gwfh.mranftl.com/api/fonts/playfair-display?download=zip&subsets=latin,latin-ext&variants=regular,italic,600,700&formats=woff2"; \
	  unzip -qo $$tmp/pf.zip -d $$tmp; \
	  for v in regular italic 600 700; do \
	    cp $$tmp/playfair-display-v*-latin_latin-ext-$$v.woff2 "$(FONT_DIR)/playfair-display-v37-latin_latin-ext-$$v.woff2"; \
	  done; rm -rf $$tmp; }
	@echo "   $$(ls -1 $(FONT_DIR) | wc -l | tr -d ' ') font files present"

install: ## Install dependencies and build the shared package
	corepack enable >/dev/null 2>&1 || true
	$(PNPM) install
	@# shared/dist must exist before server tests can import it.
	$(PNPM) build:shared

dev: ## Run the FULL LOCAL STACK: emulators + server + player + editor + website
	@echo "-> emulator UI  http://localhost:4001"
	@echo "-> api          http://localhost:4000/graphql   (your own server)"
	@echo "-> editor       http://localhost:5174/"
	@echo "-> player       http://localhost:5173/player/<id>"
	@echo "-> website      http://localhost:3000/"
	@echo
	@trap 'kill 0' EXIT INT TERM; \
	  $(FIREBASE) emulators:start --project $(PROJECT) --only auth,firestore & \
	  printf "waiting for firestore emulator"; \
	  until nc -z 127.0.0.1 8080 2>/dev/null; do printf "."; sleep 1; done; echo " up"; \
	  $(PNPM) dev:server & \
	  $(PLAYER_DEV) & \
	  $(EDITOR_DEV) & \
	  $(PNPM) dev:website & \
	  wait

dev-demo: ## Run against RichPods' PUBLIC api instead (read-only, no local data)
	@echo "-> proxy    http://127.0.0.1:4000/graphql -> api.richpods.org"
	@echo "-> player   http://localhost:5173/player/aCDKJCUpHS65yrutc34k"
	@echo "-> website  http://localhost:3000/anhoeren"
	@echo
	@trap 'kill 0' EXIT INT TERM; \
	  node tools/api-proxy.mjs 4000 & \
	  $(PLAYER_DEV) & \
	  $(PNPM) dev:website & \
	  wait

emulators: ## Run only the Firebase emulators (auth + firestore)
	$(FIREBASE) emulators:start --project $(PROJECT) --only auth,firestore

server: ## Run only the GraphQL server (needs the emulators)
	$(PNPM) dev:server

# The role is a Firebase custom claim and is what unlocks hosted podcasts,
# image uploads, Slideshow/Poll chapters and bypassing feed verification.
grant-admin: ## Make the first emulator user a super_admin
	@uid=$$(curl -s -X POST -H "Authorization: Bearer owner" -H "content-type: application/json" -d '{}' \
	  "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/$(PROJECT)/accounts:query" \
	  | python3 -c "import sys,json; u=json.load(sys.stdin).get('userInfo') or []; print(u[0]['localId'] if u else '')"); \
	if [ -z "$$uid" ]; then \
	  echo "no user yet — sign up at http://localhost:5174/ first, then rerun"; exit 1; fi; \
	echo "-> granting super_admin to $$uid"; \
	$(PNPM) --filter @richpods/server set-user-role $$uid super_admin; \
	echo "-> sign out and back in so the new token carries the claim"

proxy: ## Run only the CORS proxy to the public API
	node tools/api-proxy.mjs 4000

player: ## Run only the player
	$(PLAYER_DEV)

editor: ## Run only the editor
	$(EDITOR_DEV)

website: ## Run only the website
	$(PNPM) dev:website

build: ## Build every workspace
	$(PNPM) build:all

typecheck: ## Type-check every workspace
	$(PNPM) type-check

test: ## Run the server test suite
	$(PNPM) build:shared
	$(PNPM) test:server

audit: ## Report known vulnerabilities (runtime deps only)
	-$(PNPM) audit --prod

check: typecheck test build ## Type-check, test and build
	@echo "OK   richpods"

stop: ## Free ports 3000/4000/4001/5173/5174/8080/9099
	@for p in 3000 4000 4001 5173 5174 8080 9099; do \
	  pid=$$(lsof -ti tcp:$$p 2>/dev/null | head -1); \
	  if [ -n "$$pid" ]; then kill $$pid && echo "   stopped :$$p (pid $$pid)"; fi; \
	done; echo "-> ports clear"

clean: ## Remove build output and caches (keeps node_modules and fonts)
	rm -rf player/dist editor/dist server/build shared/dist \
	       website/.output website/.nuxt website/node_modules/.cache
