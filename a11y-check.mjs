import { chromium } from 'playwright';
import { AxeBuilder } from '@axe-core/playwright';
import path from 'node:path';

const file = 'file://' + path.resolve('wireframes/patterniq-wireframes.html');
const screens = ['overview','discover','market','watchlist','patterns','deal','portfolio','analysis','learn','sources'];

const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' }).catch(() => chromium.launch());
const context = await browser.newContext({ viewport: { width: 1400, height: 1000 } });
const page = await context.newPage();
await page.goto(file);

let total = 0;
const contrastRows = [];

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
    for (const n of x.nodes.slice(0,3)) console.log(`      ${n.html.slice(0,110)}`);
  }
}
console.log('\nTOTAL VIOLATIONS:', total);

// contrast measurement for the record
const pairs = await page.evaluate(() => {
  function lum(c){ const [r,g,b]=c.map(v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);}); return 0.2126*r+0.7152*g+0.0722*b; }
  function hex(h){ h=h.replace('#',''); return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16)]; }
  function ratio(a,b){ const L1=lum(hex(a)),L2=lum(hex(b)); const hi=Math.max(L1,L2),lo=Math.min(L1,L2); return (hi+0.05)/(lo+0.05); }
  const set = [
    ['#1E3D4C','#FAFAF9','Navy on off-white (body text)'],
    ['#1E3D4C','#FFFFFF','Navy on white (cards, tables)'],
    ['#1E3D4C','#EDF1F3','Navy on navy-tint (table headers)'],
    ['#A0522D','#FFFFFF','Terra-dark on white (subheads, eyebrow)'],
    ['#A0522D','#FAFAF9','Terra-dark on off-white'],
    ['#5A6B75','#FFFFFF','Slate on white (secondary text)'],
    ['#5A6B75','#FAFAF9','Slate on off-white'],
    ['#63727B','#FFFFFF','Mute on white (labels, uppercase 11px)'],['#63727B','#FAFAF9','Mute on off-white'],['#8E6D2B','#FFFFFF','Gold-strong on white (focus ring, current-nav marker)'],['#8E6D2B','#EDF1F3','Gold-strong on navy-tint (current-nav marker)'],
    ['#FFFFFF','#1E3D4C','White on navy (banner, active pill)'],
    ['#F2D89B','#1E3D4C','Gold-light on navy (banner emphasis)'],
    ['#B8924A','#FFFFFF','Brushed gold on white (accent borders only)'],
    ['#A0522D','#FBF4E6','Terra-dark on gold callout fill'],
  ];
  return set.map(([fg,bg,label]) => ({ fg, bg, label, ratio: +ratio(fg,bg).toFixed(2) }));
});
console.log('\nCONTRAST');
for (const p of pairs) {
  const aa = p.ratio >= 4.5 ? 'AA' : (p.ratio >= 3 ? 'AA-large only' : 'FAIL');
  const aaa = p.ratio >= 7 ? 'AAA' : '';
  console.log(`  ${String(p.ratio).padStart(6)}  ${aa.padEnd(14)} ${aaa.padEnd(4)} ${p.label}`);
}

await browser.close();
