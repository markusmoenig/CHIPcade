import React from "react";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";

export default function Home() {
  const shot = useBaseUrl("/img/screenshot.png");
  const logo = useBaseUrl("/img/logo.png");
  return (
    <Layout title="CHIPcade" description="CHIPcade docs">
      <header className="hero">
        <div className="container" style={{ padding: "1.5rem 1rem 1.25rem" }}>
          <div
            style={{
              display: "flex",
              gap: "1rem",
              alignItems: "center",
              flexWrap: "wrap",
            }}
          >
            <img
              src={logo}
              alt="CHIPcade logo"
              style={{ width: 170, height: 170, borderRadius: 20 }}
            />
            <div style={{ minWidth: 280, flex: 1 }}>
              <h1 style={{ marginBottom: ".5rem" }}>CHIPcade</h1>
              <p style={{ fontSize: "1.1rem", maxWidth: 820, marginBottom: 0 }}>
                CHIPcade is a terminal-driven 6502 fantasy console for building
                games and demos.
              </p>
              <div
                style={{
                  display: "flex",
                  gap: ".75rem",
                  flexWrap: "wrap",
                  marginTop: ".75rem",
                }}
              >
                <Link
                  className="button button--primary button--lg"
                  to="/docs/getting-started"
                >
                  Getting Started
                </Link>
                <Link
                  className="button button--secondary button--lg"
                  to="/docs/language"
                >
                  Language Guide
                </Link>
              </div>
            </div>
          </div>
        </div>
      </header>
      <main className="container" style={{ padding: "2rem 1rem 3rem" }}>
        <img className="screenshot" src={shot} alt="CHIPcade screenshot" />

        <section className="featureGrid">
          <article className="featureCard">
            <h3>6502 VM</h3>
            <p>Deterministic execution with a simple memory map.</p>
          </article>
          <article className="featureCard">
            <h3>Graphics</h3>
            <p>256x192 4bpp bitmap, 16-color global palette, 64 sprites.</p>
          </article>
          <article className="featureCard">
            <h3>C + ASM</h3>
            <p>
              Use C, ASM, or both in the same project under <code>src/</code>.
            </p>
          </article>
          <article className="featureCard">
            <h3>Debugging</h3>
            <p>
              REPL debugger with step, regs, memory, labels, and live preview.
            </p>
          </article>
        </section>

        <section style={{ marginTop: "2rem" }}>
          <h2>Quick Start</h2>
          <pre>
            <code>{`cargo install chipcade\nchipcade new my_game\nchipcade build my_game\nchipcade run my_game`}</code>
          </pre>
          <p>For ASM scaffold:</p>
          <pre>
            <code>{`chipcade new my_game --lang asm`}</code>
          </pre>
          <p>Debug with live preview:</p>
          <pre>
            <code>{`chipcade repl my_game`}</code>
          </pre>
        </section>

        <section style={{ marginTop: "2rem" }}>
          <h2>WASM</h2>
          <pre>
            <code>{`cargo run -- build my_game\nCHIPCADE_BUNDLE=my_game/build/program.bin cargo run-wasm --package CHIPcade --bin CHIPcade`}</code>
          </pre>
        </section>
      </main>
    </Layout>
  );
}
