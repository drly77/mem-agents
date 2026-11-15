// Serveur du reclasseur de mem : garde Qwen3-Reranker-4B chargé et répond sur un socket Unix (0600, aucun port réseau).
// Protocole : une ligne JSON {"q": question, "docs": [texte, ...]} -> une ligne JSON [notes] ou {"erreur": "..."}.
// Les demandes passent une par une (un seul contexte de classement).
import {getLlama, LlamaLogLevel} from "node-llama-cpp";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import {fileURLToPath} from "node:url";

const ici = path.dirname(fileURLToPath(import.meta.url));
// Jamais de repli dans /tmp (un autre utilisateur pourrait y préparer le chemin) : argument ou XDG_RUNTIME_DIR.
const chemin = process.argv[2] || (process.env.XDG_RUNTIME_DIR && path.join(process.env.XDG_RUNTIME_DIR, "mem-reclasseur.sock"));
if (!chemin) { console.error("serveur.mjs : donner le chemin du socket, ou définir XDG_RUNTIME_DIR / give the socket path, or set XDG_RUNTIME_DIR"); process.exit(2); }
const llama = await getLlama({build: "never", logLevel: LlamaLogLevel.error});
const model = await llama.loadModel({modelPath: path.join(ici, "qwen3-reranker-4b-q4_k_m.gguf")});
const ctx = await model.createRankingContext({contextSize: 2048});

let file = Promise.resolve();
const noter = (q, docs) => (file = file.then(() => (docs.length ? ctx.rankAll(q, docs) : [])));

try { fs.unlinkSync(chemin); } catch {}
process.umask(0o177);
const serveur = net.createServer(c => {
  let tampon = "";
  c.setEncoding("utf8");
  c.on("data", async morceau => {
    tampon += morceau;
    if (tampon.length > 1_000_000) return c.destroy();
    const fin = tampon.indexOf("\n");
    if (fin < 0) return;
    try {
      const {q, docs} = JSON.parse(tampon.slice(0, fin));
      if (typeof q !== "string" || !Array.isArray(docs) || docs.some(d => typeof d !== "string")) throw new Error("forme");
      c.end(JSON.stringify(await noter(q, docs)) + "\n");
    } catch (e) {
      c.end(JSON.stringify({erreur: String(e.message || e).slice(0, 80)}) + "\n");
    }
  });
  c.on("error", () => {});
});
serveur.listen(chemin, () => console.log(`reclasseur prêt sur ${chemin} / reranker ready on ${chemin}`));
for (const s of ["SIGTERM", "SIGINT"]) process.on(s, () => { serveur.close(); try { fs.unlinkSync(chemin); } catch {} process.exit(0); });
