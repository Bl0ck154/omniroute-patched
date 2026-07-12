import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import path from "node:path";

const [repoRoot, upstreamRoot, artifactPath, outputPath] = process.argv.slice(2);
if (!outputPath) throw new Error("usage: make-manifest.mjs repo upstream artifact output");

const baseline = JSON.parse(readFileSync(path.join(repoRoot, "config/baseline.json"), "utf8"));
const pkg = JSON.parse(readFileSync(path.join(upstreamRoot, "package.json"), "utf8"));
const sha256 = (file) => createHash("sha256").update(readFileSync(file)).digest("hex");
const git = (...args) => execFileSync("git", ["-C", upstreamRoot, ...args], { encoding: "utf8" }).trim();
const patchFiles = baseline.patches || ["patches/quota-ui.patch"];
const patches = patchFiles.map((file) => ({ file, sha256: sha256(path.join(repoRoot, file)) }));

const manifest = {
  schemaVersion: 1,
  package: "omniroute",
  upstreamVersion: pkg.version,
  upstreamRef: process.env.UPSTREAM_REF || baseline.upstreamRef || `v${pkg.version}`,
  upstreamCommit: git("rev-parse", "HEAD"),
  patchRevision: Number(process.env.PATCH_REVISION || baseline.patchRevision),
  patchSha256: sha256(path.join(repoRoot, "patches/quota-ui.patch")),
  patches,
  artifact: path.basename(artifactPath),
  artifactSha256: sha256(artifactPath),
  nodeVersion: process.version,
  platform: "linux-x64",
  buildWorkflow: process.env.GITHUB_WORKFLOW || "local",
  buildRunId: process.env.GITHUB_RUN_ID || null,
  builtAt: new Date().toISOString()
};

writeFileSync(outputPath, JSON.stringify(manifest, null, 2) + "\n");
console.log(JSON.stringify(manifest, null, 2));
