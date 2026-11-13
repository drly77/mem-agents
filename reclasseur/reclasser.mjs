// Reclasseur de mem : lit {"q": question, "docs": [texte, ...]} sur l'entrée standard,
// écrit la liste des notes de pertinence (0 à 1) sur la sortie standard, en JSON.
// Qwen3-Reranker-4B Q4_K_M (GGUF de giladgd, auteur de node-llama-cpp ; sha256 941f7d1d…), llama.cpp en local : ni réseau, ni compilation.
import {getLlama, LlamaLogLevel} from "node-llama-cpp";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const ici = path.dirname(fileURLToPath(import.meta.url));
const {q, docs} = JSON.parse(fs.readFileSync(0, "utf8"));
const llama = await getLlama({build: "never", logLevel: LlamaLogLevel.error});
const model = await llama.loadModel({modelPath: path.join(ici, "qwen3-reranker-4b-q4_k_m.gguf")});
const ctx = await model.createRankingContext({contextSize: 2048});
process.stdout.write(JSON.stringify(docs.length ? await ctx.rankAll(q, docs) : []));
await llama.dispose();
