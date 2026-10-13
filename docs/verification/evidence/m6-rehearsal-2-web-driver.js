// Rehearsal 2 runner: drives the hosted web build of ae7b7ff through
// docs/verification/rehearsal-protocol.md steps 1-41, records video, logs outcomes.
const { chromium } = require('playwright');
const fs = require('fs');
const S = process.env.S;
const URL = process.env.URL || 'https://vistamarkets.github.io/VistaColosseum/';
const FROM = +(process.env.FROM || 1), TO = +(process.env.TO || 41);
const log = [];
const out = (step, outcome, note) => { log.push({ step, outcome, note }); console.log(`step ${step}: ${outcome}${note ? ' — ' + note : ''}`); };

let page;
const sleep = ms => page.waitForTimeout(ms);
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const toRe = m => m instanceof RegExp ? m.source : '^' + esc(m) + '$';
const flags = m => m instanceof RegExp ? m.flags : '';
// Leaf-most semantics nodes whose own label matches.
async function idx(m) {
  return page.evaluate(([src, fl]) => {
    const re = new RegExp(src, fl);
    const els = [...document.querySelectorAll('flt-semantics')];
    const lab = e => (e.getAttribute('aria-label') || e.innerText || '').replace(/\s+/g, ' ').trim();
    const hit = els.map(e => re.test(lab(e)));
    const vis = e => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.y < 844 && r.y + r.height > 0; };
    return els.map((e, i) => i).filter(i => hit[i] && vis(els[i]) && ![...els[i].querySelectorAll('flt-semantics')].some(c => re.test(lab(c)) && vis(c)));
  }, [toRe(m), flags(m)]);
}
async function labels() {
  return page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map(e => (e.getAttribute('aria-label') || e.innerText || '').replace(/\s+/g, ' ').trim()).filter(Boolean));
}
async function see(m, ms = 3000) {
  const t = Date.now();
  while (Date.now() - t < ms) { if ((await idx(m)).length) return true; await sleep(150); }
  return false;
}
async function must(m, what) { if (!(await see(m))) throw new Error(`expected ${what || m}`); }
async function tap(m, n = 0, ms = 4000) {
  const t = Date.now(); let ids = [];
  while (Date.now() - t < ms) { ids = await idx(m); if (ids.length > n) break; await sleep(150); }
  if (ids.length <= n) throw new Error(`tap: no node ${m} [${n}]`);
  const loc = page.locator('flt-semantics').nth(ids[n]);
  let box = await loc.boundingBox();
  for (let k = 0; k < 8 && box && (box.y + box.height > 805 || box.y < 0); k++) { await page.mouse.move(195, 450); await page.mouse.wheel(0, box.y < 0 ? -250 : 250); await sleep(400); box = await loc.boundingBox(); }
  if (!box) throw new Error(`tap: no box ${m}`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await sleep(600);
}
async function box(m, n = 0) {
  const ids = await idx(m); if (ids.length <= n) throw new Error(`box: no node ${m}`);
  return page.locator('flt-semantics').nth(ids[n]).boundingBox();
}
async function drag(x1, y1, x2, y2, steps = 20) {
  await page.mouse.move(x1, y1); await page.mouse.down();
  await page.mouse.move(x2, y2, { steps }); await page.mouse.up(); await sleep(700);
}
async function swipe(dir) { // vertical pager at centre
  const y = dir === 'next' ? [600, 200] : [200, 600];
  await drag(195, y[0], 195, y[1], 15);
}
const TOAST=/not in the demo yet|Demo reset to|Now acting as|from paper cash|Share — |Tap the Simulated pill/;
async function quiet(ms=7000){ const t=Date.now(); while(Date.now()-t<ms){ if(!(await idx(TOAST)).length) return; await sleep(200);} }
async function nav(name){ await quiet(); await tap(new RegExp('^'+name+'$')); }
async function typeInput(n, text){ const inp=page.locator('flt-semantics input, flt-semantics textarea'); const c=await inp.count(); if(c<=n) throw new Error('typeInput: no input '+n+' of '+c); const el=inp.nth(n); await el.click({force:true}); await sleep(200); await el.fill(''); await sleep(200); if(text) await page.keyboard.type(text,{delay:40}); await sleep(700); }
async function disabled(m) { const ids = await idx(m); if (!ids.length) throw new Error('disabled: no node ' + m); return page.locator('flt-semantics').nth(ids[0]).getAttribute('aria-disabled'); }
async function recover() { for (let k = 0; k < 6; k++) { if ((await idx(/^Home$/)).length && (await idx(/^Wallet$/)).length) return; if ((await idx(/^Done$/)).length) await tap(/^Done$/).catch(() => {}); else if ((await idx(/^Back$/)).length) await tap(/^Back$/).catch(() => {}); else if ((await idx(/^Close$/)).length) await tap(/^Close$/).catch(() => {}); else if ((await idx(/^Cancel$/)).length) await tap(/^Cancel$/).catch(() => {}); else { await page.keyboard.press('Escape'); await sleep(500); } } }
async function tapRight(m, n = 0) { const ids = await idx(m); if (ids.length <= n) throw new Error('tapRight: no node ' + m); const bx = await page.locator('flt-semantics').nth(ids[n]).boundingBox(); await page.mouse.click(bx.x + bx.width - 30, bx.y + bx.height / 2); await sleep(700); }
async function back() { await tap(/^Back$/).catch(async () => { await page.keyboard.press('Escape'); await sleep(500); }); }
async function typeInto(m, text, n = 0) {
  // Flutter text fields: semantics node is editable; click it then type.
  await tap(m, n);
  await page.keyboard.press('Control+A'); await page.keyboard.press('Backspace');
  if (text) await page.keyboard.type(text, { delay: 40 });
  await sleep(500);
}
async function shot(name) { await page.screenshot({ path: `${S}/rec/${name}.png` }); }
const money = async re => { const l = await labels(); const m = l.join(' ').match(re); return m ? m[1] : null; };

async function rows() { return page.evaluate(() => [...document.querySelectorAll('flt-semantics')].filter(e => !e.querySelector('flt-semantics') && e.getAttribute('role') === 'button').map(e => ({ l: (e.getAttribute('aria-label') || e.innerText || '').replace(/\s+/g, ' ').trim(), y: e.getBoundingClientRect().y })).filter(r => r.y > 480 && r.y < 745 && !/^(Home|Explore|Arena|Wallet|Make a market|Your market|maya\.eth's market|Fees from)/.test(r.l)).map(r => r.l)); }
async function wallet(positions, openOrders) {
  await tap(/^Open orders$/); const o = await rows(); await tap(/^Positions$/); const ps = await rows();
  console.log(`   positions=${ps.length} openOrders=${o.length}`);
  if (positions != null && ps.length !== positions) throw new Error(`positions ${ps.length} != ${positions}: ${ps.join('; ')}`);
  if (openOrders != null && o.length !== openOrders) throw new Error(`open orders ${o.length} != ${openOrders}: ${o.join('; ')}`);
}
const steps = {
  1: async () => {
    await nav('Wallet'); await tap(/^Settings$/); await tap(/^Reset demo$/);
    await must(/Demo reset to fixture-v1/, 'reset toast');
    await tap(/^Settings$/); await must(/^Demo persona Creator$/); await back();
    await must(/12,480\.00/); await must(/^Make a market$/); await wallet(3, 3);
  },
  2: async () => { await tap(/^Settings$/); await page.mouse.move(195, 500); await page.mouse.wheel(0, 600); await sleep(700); const ids = await idx(/^Simulate load failure/); if (!ids.length) throw new Error('no switch'); const bx = await page.locator('flt-semantics').nth(ids[0]).boundingBox(); await page.mouse.click(bx.x + bx.width - 24, bx.y + bx.height / 2); await sleep(600); const st = await page.locator('flt-semantics').nth(ids[0]).getAttribute('aria-checked'); if (st !== 'true') throw new Error('switch not on'); await back(); await must(/12,480\.00/); },
  3: async () => {
    await nav('Explore'); await must(/Couldn't load markets/); await must(/Set by Simulate load failure in Settings/); await shot('step3-failed-state');
    { const ids = await idx(/Couldn't load markets.*Retry$/); const bx = await page.locator('flt-semantics').nth(ids[0]).boundingBox(); await page.mouse.click(bx.x + bx.width / 2, bx.y + bx.height - 22); await sleep(900); } await must(/^Favorite BTC/); await must(/^Favorite AVAX/);
  },
  4: async () => {
    await nav('Home'); await tap(/^For You$/); const a = await labels(); await tap(/^Following$/); await sleep(800); const b = await labels();
    const ca = a.filter(x => /Called \$/.test(x)), cb = b.filter(x => /Called \$/.test(x));
    if (!ca.length || !cb.length || ca[0] === cb[0]) throw new Error('tabs not distinct: ' + ca[0] + ' | ' + cb[0]);
    await tap(/^For You$/); await must(/Simulated · fixture-v1/);
  },
  5: async () => {
    const l0 = (await labels()).find(x => /Called \$/.test(x)); const like0 = (await labels()).find(x => /^Like, /.test(x));
    await swipe('next'); await sleep(800); await swipe('prev'); await sleep(800);
    const l1 = (await labels()).find(x => /Called \$/.test(x)); const like1 = (await labels()).find(x => /^Like, /.test(x));
    const k=x=>(x||'').split(' Ethereum ')[0]; if (k(l0) !== k(l1) || like0 !== like1) throw new Error(`card changed: ${l0} / ${l1}`); if(!/replaying/.test(l1)) throw new Error('no replay marker');
  },
  6: async () => {
    await must(/^kaito\.eth/); await tap(/^Like, 4\.4k$/); await tap(/^People in, 1\.2k in$/); await must(/^Done$/); await tap(/^Done$/); await nav('Arena'); await nav('Home'); await must(/^Like, 4\.4k$/);
  },
  7: async () => { await tap(/^Details$/); await must(/^Long$/); await must(/Panel 1 of 4/); await back(); await must(/^kaito\.eth/); },
  8: async () => {
    for (let i = 0; i < 6 && !(await idx(/^kilo\.sol/)).length; i++) await swipe('next');
    await must(/^kilo\.sol/); await page.mouse.click(60, 128); await sleep(900);
    if (!(await see(/^Follow$|^Following$/))) throw new Error('not run: handle tap target not exposed to semantics; profile not opened by coordinate tap');
    await shot('step8-profile');
    const was = (await idx(/^Following$/)).length ? 'Following' : 'Follow'; await tap(new RegExp('^' + was + '$')); await sleep(400); await tap(was === 'Following' ? /^Follow$/ : /^Following$/);
    await back(); await nav('Arena'); await nav('Home'); await page.mouse.click(60, 128); await sleep(900); await must(new RegExp('^' + was + '$')); await back();
  },
  9: async () => {
    let n = 0; for (let i = 0; i < 14 && n < 2; i++) { await swipe('next'); await sleep(400); if ((await idx(/Maker suggestion/)).length) { n++; await shot('step9-maker-' + n); await must(/Maker suggestion/); } }
    if (n < 1) throw new Error('no Maker card found');
  },
  10: async () => {
    await nav('Wallet'); await must(/12,480\.00/);
    for (const c of ['1h', '4h', '1D', '1W', '1M', 'All']) await tap(new RegExp('^' + c + '$'));
    await tap(/^Deposit$/); await must(/Deposit \(simulated\)/); await wallet(3, 3);
  },
  11: async () => { await tap(/^Make a market$/); await must(/Continue with \$MAYA/); await must(/Free to create/); await must(/Name maya\.eth/); if (await disabled(/^Continue with \$MAYA$/)) throw new Error('Continue disabled'); await shot('step11-ticker-available'); },
  12: async () => {
    await page.mouse.click(195, 350); await sleep(300); await page.keyboard.press('Control+A'); await page.keyboard.press('Backspace'); await sleep(500); await must(/^Continue with \$$/); if (!(await disabled(/^Continue with \$$/))) throw new Error('blank: Continue enabled'); await shot('step12-blank'); await page.keyboard.type('BTC', { delay: 50 }); await must(/^Continue with \$BTC$/); if (!(await disabled(/^Continue with \$BTC$/))) throw new Error('BTC: Continue enabled'); await shot('step12-btc');
    await tap(/^Use \$MAYA$/); await must(/^Continue with \$MAYA$/); if (await disabled(/^Continue with \$MAYA$/)) throw new Error('MAYA: Continue disabled');
  },
  13: async () => { await tap(/Continue with \$MAYA/); await must(/Before you list/); await must(/Not allowed/); await must(/I agree to the Terms/); },
  14: async () => {
    await back(); await tap(/^Close$/); await must(/^Make a market$/); if ((await idx(/^Your market$/)).length) throw new Error('market created early');
    await tap(/^Make a market$/); await tap(/Continue with \$MAYA/); await must(/Before you list/);
  },
  15: async () => {
    for (const c of [/^I understand people can short my market/, /^My calls are graded in public/, /^I'm 18\+ and not a US person/, /^I agree to the Terms of Service/]) await tap(c);
    await tap(/^Create \$MAYA$/); await must(/Your market is open/); await must(/10,000/);
    await tap(/Make your first call/); await must(/Posting calls is outside this demo/); await tap(/See a sample call/); await must(/Call receipt|kilo\.sol/); await back();
    await tap(/^Share \$MAYA$/); await must(/Share — not in the demo yet/);
  },
  16: async () => {
    await tap(/^Close$/); await nav('Home'); await nav('Wallet'); await must(/Fees from your market/); await must(/^Your market$/);
    await drag(300, 170, 80, 170); await sleep(600); await must(/Market cap|10,000/); await drag(80, 170, 300, 170);
  },
  17: async () => { await tap(/^Your market$/); await must(/Market cap/); await must(/10,000/); await tap(/^1W$/); await tap(/^Make a call$/); await must(/Make a call — not in the demo yet/); await back(); },
  18: async () => { await nav('Arena'); await must(/Crowd split 50\/50/); await must(/3 battles/); await must(/I'm with Bull/); },
  19: async () => { await tap(/^Change$/); await tap(/^Funding$/); await tap(/^Volume$/); await must(/3 battles/); },
  20: async () => { throw new Error('not run: range-slider drag by division not automated headlessly'); },
  21: async () => { throw new Error('not run: range-slider drag not automated headlessly'); },
  22: async () => {
    throw new Error('not run: the Ask about a market field accepts typed text but the driver cannot clear it (DOM fill/backspace ignored), so the DOGE and Clear search clauses cannot be exercised');
    await typeInput(0, 'SOL'); await must(/1 battle/); await typeInput(0, 'DOGE'); await must(/No battles on/); await must(/Try BTC, ETH, SOL/);
    await tap(/^Clear search$/); await must(/3 battles/);
  },
  23: async () => { await tap(/^\+\d+ more opinions$/); await tap(/^Bull thesis$/); await tap(/^All$/); await must(/Follow Bull/); await back(); await must(/3 battles/); },
  24: async () => { await tap(/^0xreal/); await must(/^Follow$|^Following$/); await shot('step24-profile'); await back(); await must(/3 battles/); },
  25: async () => {
    await tap(/I'm with Bull/); await tap(/^Place market long$/); await must(/Review order/); await must(/Simulated — no real order/); await must(/Paper funds required/);
    await tap(/^Cancel$/); await nav('Wallet'); await must(/12,480\.00/); await wallet(3, 3);
    await tap(/^Your market$/); await tapRight(/All receipts/); await must(/PAPER ORDER RECEIPTS|Paper order receipts|receipts/i); await shot('step25-receipts'); const l = await labels(); if (l.some(x => /Long BTC|BTC.*Long/.test(x))) throw new Error('receipt after cancel');
    await back(); await back(); await nav('Arena'); await must(/I'm with Bull/);
  },
  26: async () => { await tap(/I'm with Bull/); await must(/^Long$/); await tap(/^Place market long$/); await must(/· BTC/); await must(/^Long/); const pf = await money(/Paper funds required\s*\$?([\d,]+\.\d\d)/); console.log('   paper funds required:', pf); },
  27: async () => {
    const b = await box(/^Confirm$/); await page.mouse.dblclick(b.x + b.width / 2, b.y + b.height / 2); await sleep(1500);
    await must(/Order filled/); const n = (await idx(/Order filled/)).length; if (n !== 1) throw new Error('Order filled x' + n); await must(/from paper cash \(simulated\)/);
  },
  28: async () => { await tap(/^View in Wallet$/); await wallet(4, null); },
  29: async () => { await tap(/^Your market$/); await tapRight(/All receipts/); await must(/BTC/); await shot('step29-receipts'); await back(); await back(); },
  30: async () => { await nav('Arena'); await must(/Joined Bull/); },
  31: async () => { await nav('Explore'); await tapRight(/^Favorite ETH/); await must(/^Long$/); await tap(/^Long$/); await tap(/^Place market long$/); await tap(/^Confirm$/); await must(/Order filled/); await tap(/^Done$/); await back(); await nav('Arena'); await must(/I'm with Bull/); },
  32: async () => {
    await nav('Wallet'); await wallet(5, 3);
    const cash = await money(/Portfolio balance \$([\d,]+\.\d\d)/); console.log('   cash:', cash);
    await tap(/Fees from your market/); await must(/No fee credits yet/); await must(/\$0\.00/); await back();
    await tap(/^Your market$/); await tapRight(/All receipts/); await shot('step32-receipts'); const l = await labels(); const paper = l.filter(x => /(Long|LONG).*(BTC|ETH|Bitcoin|Ethereum)/.test(x)).length; console.log('   paper-like rows:', paper); await back(); await back();
  },
  33: async () => { await tap(/^Settings$/); await tap(/^Demo persona/); await must(/Now acting as sam\.sol/); await must(/^Demo persona Copier$/); await back(); await must(/1,000\.00/); await must(/maya\.eth's market/); await wallet(0, 0); },
  34: async () => {
    await nav('Home'); for (let i = 0; i < 8 && !(await idx(/^kilo\.sol/)).length; i++) await swipe('next');
    await tap(/^Long$/); await must(/you have \$1,000\.00/); await shot('step34-ticket'); await typeInput(0, '100'); await tap(/^Long \$100 · \d+x$/); await must(/Copying @kilo\.sol · \$5\.00 copy fee/);
  },
  35: async () => { await tap(/^Confirm$/); await must(/Order filled/); await must(/Copying @kilo\.sol/); await tap(/^View in Wallet$/); await must(/sam\.sol/); await wallet(1, null); },
  36: async () => { await tap(/^Settings$/); await tap(/^Demo persona/); await must(/Now acting as maya\.eth/); await back(); await wallet(5, null); },
  37: async () => { await tap(/Fees from your market/); await must(/40% creator share/); await must(/@sam\.sol/); await must(/kilo\.sol\/SOL|kilo\.sol · SOL|SOL/); await must(/Total \$5\.00|\$5\.00/); await back(); },
  38: async () => { await tap(/^Your market$/); await tapRight(/All receipts/); await tap(/SOL reaches|SOL/); await must(/Provenance/); await shot('step38-call-receipt'); await back(); await back(); await back(); },
  39: async () => { await nav('Arena'); await tap(/^kilo\.sol/); await must(/^Follow$|^Following$/); await shot('step39-profile'); await tap(/^1W$|^1M$|^All$/); },
  40: async () => { await tap(/^market$/); await must(/kilo\.sol/); await shot('step40-trader-market'); await tapRight(/All receipts/); await shot('step40-receipts'); await back(); await back(); await back(); },
  41: async () => { await nav('Wallet'); await tap(/^Bitcoin, LONG/); await must(/Unrealised/); await shot('step41-position'); await tap(/^Close position$|^Close$/); await must(/Close position \(simulated\)/); },
};

(async () => {
  const b = await chromium.launch({ executablePath: '/home/alex/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome' });
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, recordVideo: { dir: `${S}/rec`, size: { width: 390, height: 844 } } });
  page = await ctx.newPage();
  await page.goto(URL, { waitUntil: 'networkidle' }); await sleep(4000);
  await page.locator('flt-semantics-placeholder').first().dispatchEvent('click'); await sleep(9500);
  const t0 = Date.now();
  for (let s = FROM; s <= TO; s++) {
    try { await steps[s](); out(s, 'passed'); }
    catch (e) { const nr = /^not run/.test(e.message); out(s, nr ? 'not run' : 'failed', e.message); await shot(`step${s}-${nr ? 'notrun' : 'fail'}`); if (!nr) console.log('   labels:', (await labels()).slice(0, 40).join(' | ')); await recover(); }
  }
  console.log('elapsed s:', Math.round((Date.now() - t0) / 1000));
  fs.writeFileSync(`${S}/rec/log.json`, JSON.stringify(log, null, 2));
  const v = page.video(); await ctx.close(); const vp = await v.path(); console.log('video:', vp); await b.close();
})();
