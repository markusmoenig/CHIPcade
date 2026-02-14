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
            <p>
              Build one deterministic 64 KB image and run it locally or in the
              browser via WASM.
            </p>
          </article>
          <article className="featureCard">
            <h3>Graphics</h3>
            <p>256x192 4bpp bitmap, 16-color global palette, 64 sprites.</p>
          </article>
          <article className="featureCard">
            <h3>C + ASM</h3>
            <p>
              CHIPcade compiles C to 6502 assembly, so you can mix both
              seamlessly.
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
          <p>1) Install Rust (required):</p>
          <pre>
            <code>{`https://www.rust-lang.org/tools/install`}</code>
          </pre>
          <p>2) Install CHIPcade:</p>
          <pre>
            <code>{`cargo install chipcade`}</code>
          </pre>
          <p>3) Create a project:</p>
          <pre>
            <code>{`chipcade new my_game`}</code>
          </pre>
          <p>4) Enter the project folder:</p>
          <pre>
            <code>{`cd my_game`}</code>
          </pre>
          <p>5) Build and run:</p>
          <pre>
            <code>{`chipcade build\nchipcade run`}</code>
          </pre>
          <p>For ASM scaffold:</p>
          <pre>
            <code>{`chipcade new my_game --lang asm`}</code>
          </pre>
          <p>Debug with live preview:</p>
          <pre>
            <code>{`chipcade repl`}</code>
          </pre>
          <p>REPL essentials:</p>
          <pre>
            <code>{`debug        start/reset session\nstep 50      step instructions\nrun          run continuously\npause        pause running session\nline         show current C + ASM location\nmem VRAM 32  inspect memory\nlabels SPR_  filter labels\nstop         stop debug session`}</code>
          </pre>
        </section>

        <section style={{ marginTop: "2rem" }}>
          <h2>WASM</h2>
          <pre>
            <code>{`cargo install cargo-run-wasm\nchipcade wasm`}</code>
          </pre>
        </section>
      </main>
    </Layout>
  );
}
