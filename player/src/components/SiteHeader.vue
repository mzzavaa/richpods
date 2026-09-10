<template>
    <RipoSiteHeader
        fixed
        burger-only
        :open-menu-label="t('header.menu')"
        :close-menu-label="t('header.menu')"
    >
        <template #mobile-nav="{ close }">
            <RipoButton
                as="link"
                size="large"
                block
                :href="websiteUrl('header.homePath')"
                @click="close"
            >
                <template #icon-left><NavIcon name="home" /></template>
                {{ t("header.home") }}
            </RipoButton>
            <RipoButton
                as="link"
                size="large"
                block
                :href="websiteUrl('header.listenPath')"
                @click="close"
            >
                <template #icon-left><NavIcon name="play" /></template>
                {{ t("header.listen") }}
            </RipoButton>
            <RipoButton
                as="link"
                size="large"
                block
                :href="websiteUrl('header.teamPath')"
                @click="close"
            >
                <template #icon-left><NavIcon name="team" /></template>
                {{ t("header.team") }}
            </RipoButton>
            <RipoButton
                as="link"
                size="large"
                block
                :href="websiteUrl('header.contactPath')"
                @click="close"
            >
                <template #icon-left><NavIcon name="mail" /></template>
                {{ t("header.contact") }}
            </RipoButton>
        </template>

        <template #logo>
            <a class="logo-link" :href="websiteUrl('header.homePath')" aria-label="Incredible Podcasts, home">
                <svg class="logo-mark" viewBox="0 0 64 64" aria-hidden="true">
                    <defs>
                        <linearGradient id="incSlit" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0" stop-color="#EBD3AC" />
                            <stop offset="1" stop-color="#B8925A" />
                        </linearGradient>
                    </defs>
                    <path d="M32 8 L37 50 L27 50 Z" fill="url(#incSlit)" />
                    <rect x="14" y="52" width="36" height="1.6" fill="#B8925A" opacity=".45" />
                </svg>
                <span class="wordmark">
                    <span class="wordmark__name">Incredible</span>
                    <span class="wordmark__rule" aria-hidden="true"></span>
                    <span class="wordmark__sub">Podcasts</span>
                </span>
            </a>
        </template>
    </RipoSiteHeader>
</template>
<script setup lang="ts">
import { useI18n } from "vue-i18n";
import RipoSiteHeader from "@richpods/shared/components/RipoSiteHeader.vue";
import RipoButton from "@richpods/shared/components/RipoButton.vue";
import NavIcon from "@richpods/shared/components/NavIcon.vue";

const { t } = useI18n();
const baseWebsiteUrl = (import.meta.env.VITE_WEBSITE_URL || "").replace(/\/+$/, "");

function websiteUrl(pathKey: string) {
    return `${baseWebsiteUrl}${t(pathKey)}`;
}
</script>
<style scoped lang="scss">
.logo-link {
    display: flex;
    align-items: center;
    height: 100%;
}

.logo-link {
    gap: 10px;
    text-decoration: none;
}

.logo-mark {
    width: 26px;
    height: 26px;
    flex: none;
}

/* Mirrors .wordmark in the shared Incredible theme
   (incredible.builders/themes/incredible/assets/css/components.css). */
.wordmark {
    display: inline-flex;
    flex-direction: column;
    align-items: center;
    gap: 0.34em;
    line-height: 1;
}

.wordmark__name {
    font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    font-weight: 300;
    font-size: 1.05rem;
    letter-spacing: 0.34em;
    text-indent: 0.34em;
    text-transform: uppercase;
    color: #f2efe9;
}

.wordmark__rule {
    width: 100%;
    height: 1px;
    background: #b8925a;
    opacity: 0.55;
}

.wordmark__sub {
    font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    font-weight: 400;
    font-size: 0.58rem;
    letter-spacing: 0.28em;
    text-indent: 0.28em;
    text-transform: uppercase;
    color: #b8925a;
}
</style>
