import { chromium } from 'playwright';
import { AxeBuilder } from '@axe-core/playwright';
import path from 'node:path';

const file = 'file://' + path.resolve('wireframes/patterniq-wireframes.html');
const screens = ['overview','discover','market','watchlist','patterns','deal','portfolio','analysis','learn','sources'];
const themes = ['terminal','research'];

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(() => chromium.launch());
const context = await browser.newContext({ viewport: { width: 1500, height: 1000 } });
const page = await context.newPage();
await page.goto(file);

let total = 0;
for (const theme of themes) {
  console.log(`\n=== THEME: ${theme} ===`);
  await page.evaluate((t) => document.documentElement.setAttribute('data-theme', t), theme);
  for (const s of screens) {
    await page.evaluate((id) => {
      document.querySelectorAll('.screen').forEach(el => el.hidden = (el.id !== id));
    }, s);
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])
      .analyze();
    const v = results.violations;
    total += v.length;
    console.log(`${s.padEnd(11)} violations: ${v.length}`);
    for (const x of v) {
      console.log(`   [${x.impact}] ${x.id}: ${x.help}`);
      for (const n of x.nodes.slice(0,4)) {
        console.log(`      ${n.html.slice(0,120)}`);
        if (n.any?.[0]?.message) console.log(`        -> ${n.any[0].message.slice(0,160)}`);
      }
    }
  }
}
console.log('\nTOTAL VIOLATIONS (both themes):', total);

const pairs = await page.evaluate(() => {
  function lum(c){ const [r,g,b]=c.map(v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);}); return 0.2126*r+0.7152*g+0.0722*b; }
  function hex(h){ h=h.replace('#',''); return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16)]; }
  function ratio(a,b){ const L1=lum(hex(a)),L2=lum(hex(b)); const hi=Math.max(L1,L2),lo=Math.min(L1,L2); return (hi+0.05)/(lo+0.05); }
  const T = { bg:'#0A0E14', panel:'#111820', panel2:'#18212C', head:'#1B2530' };
  const set = [
    ['#D6E1EC', T.bg,    'Terminal text on page background'],
    ['#D6E1EC', T.panel, 'Terminal text on panel'],
    ['#9BAFC4', T.panel, 'Terminal dim text on panel (notes, table body)'],
    ['#9BAFC4', T.head,  'Terminal dim text on panel header'],
    ['#7C90A4', T.panel, 'Terminal faint text on panel (labels, tiny)'],
    ['#7C90A4', T.bg,    'Terminal faint text on page background'],
    ['#3DD68C', T.panel, 'Up green on panel'],
    ['#3DD68C', T.bg,    'Up green on page background'],
    ['#FF8080', T.panel, 'Down red on panel'],
    ['#FF8080', T.bg,    'Down red on page background'],
    ['#E0A93C', T.panel, 'Gold accent on panel'],
    ['#5BC8E8', T.panel, 'Cyan on panel'],
    ['#A99BF0', T.panel, 'Violet (pattern tag) on panel'],
    ['#0A0E14', '#E0A93C','Background ink on gold (active pill, skip link)'],
    ['#1E3D4C', '#FAFAF9','Research text on background'],
    ['#63727B', '#FFFFFF','Research faint on panel'],
    ['#1F7A52', '#FFFFFF','Research up green on panel'],
    ['#B03A3A', '#FFFFFF','Research down red on panel'],
    ['#8E6D2B', '#FFFFFF','Research gold on panel'],
    ['#5B4EA8', '#FFFFFF','Research violet on panel'],
    ['#1E6E86', '#FFFFFF','Research cyan on panel'],
  ];
  return set.map(([fg,bg,label]) => ({ fg, bg, label, ratio: +ratio(fg,bg).toFixed(2) }));
});
console.log('\nCONTRAST');
for (const p of pairs) {
  const aa = p.ratio >= 4.5 ? 'AA' : (p.ratio >= 3 ? 'AA-large/non-text' : 'FAIL');
  const aaa = p.ratio >= 7 ? 'AAA' : '';
  console.log(`  ${String(p.ratio).padStart(6)}  ${aa.padEnd(18)} ${aaa.padEnd(4)} ${p.label}`);
}

await browser.close();
