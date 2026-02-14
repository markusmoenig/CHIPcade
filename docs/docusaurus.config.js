// @ts-check

const chipcadeLightTheme = {
  plain: { color: "#0f172a", backgroundColor: "#f8fafc" },
  styles: [
    { types: ["comment"], style: { color: "#64748b", fontStyle: "italic" } },
    { types: ["keyword"], style: { color: "#0f766e" } },
    { types: ["string"], style: { color: "#0369a1" } },
    { types: ["function"], style: { color: "#1d4ed8", fontWeight: "bold" } },
    { types: ["number", "boolean"], style: { color: "#7c3aed" } },
  ],
};

const chipcadeDarkTheme = {
  plain: { color: "#e2e8f0", backgroundColor: "#0f172a" },
  styles: [
    { types: ["comment"], style: { color: "#94a3b8", fontStyle: "italic" } },
    { types: ["keyword"], style: { color: "#2dd4bf" } },
    { types: ["string"], style: { color: "#38bdf8" } },
    { types: ["function"], style: { color: "#60a5fa", fontWeight: "bold" } },
    { types: ["number", "boolean"], style: { color: "#c084fc" } },
  ],
};

const config = {
  title: "CHIPcade",
  tagline: "Terminal-driven 6502 game toolkit",
  favicon: "img/logo.png",
  url: "https://markusmoenig.github.io",
  baseUrl: "/CHIPcade/",
  organizationName: "markusmoenig",
  projectName: "CHIPcade",
  onBrokenLinks: "warn",
  onBrokenMarkdownLinks: "warn",
  i18n: { defaultLocale: "en", locales: ["en"] },
  headTags: [
    {
      tagName: "meta",
      attributes: {
        name: "description",
        content:
          "CHIPcade is a terminal-driven 6502 fantasy console with C and ASM support, REPL debugging, and live preview.",
      },
    },
    {
      tagName: "meta",
      attributes: {
        name: "keywords",
        content:
          "CHIPcade,6502,fantasy console,retro game development,assembly,C language",
      },
    },
    {
      tagName: "meta",
      attributes: {
        property: "og:title",
        content: "CHIPcade — 6502 Fantasy Console",
      },
    },
    {
      tagName: "meta",
      attributes: {
        property: "og:description",
        content:
          "Terminal-driven 6502 fantasy console with C + ASM, debugger REPL, and live preview.",
      },
    },
    {
      tagName: "meta",
      attributes: {
        property: "og:image",
        content: "https://markusmoenig.github.io/CHIPcade/img/screenshot.png",
      },
    },
  ],
  presets: [
    [
      "classic",
      {
        docs: { sidebarPath: require.resolve("./sidebars.js") },
        blog: false,
        theme: { customCss: require.resolve("./src/css/custom.css") },
      },
    ],
  ],
  themeConfig: {
    prism: {
      theme: chipcadeLightTheme,
      darkTheme: chipcadeDarkTheme,
      additionalLanguages: ["toml", "asm6502"],
    },
    navbar: {
      title: "CHIPcade",
      logo: {
        alt: "CHIPcade Logo",
        src: "img/logo-white.png",
        srcDark: "img/logo.png",
      },
      items: [
        {
          type: "docSidebar",
          sidebarId: "tutorialSidebar",
          position: "left",
          label: "Docs",
        },
        {
          type: "html",
          position: "right",
          value: `
            <a href="https://github.com/markusmoenig/CHIPcade" class="navbar-icon" title="CHIPcade on GitHub">
              <img src="https://img.shields.io/badge/GitHub-CHIPcade-0ea5e9?style=flat&logo=github" alt="CHIPcade on GitHub"/>
            </a>
          `,
        },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [{ label: "Getting Started", to: "/docs/getting-started" }],
        },
        {
          title: "Project",
          items: [
            {
              label: "GitHub",
              href: "https://github.com/markusmoenig/CHIPcade",
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} CHIPcade`,
    },
  },
};

module.exports = config;
