// Copy this file to a Classic app Resources/app.js to run the lifecycle regression.
const A = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'Rapid presentation regression', backgroundColor: '#f4f4f7' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const navButton = Ti.UI.createButton({ title: 'Nav source' });
win.setRightNavButton(navButton);
const button = Ti.UI.createButton({ title: 'Normal button', top: 80, width: 220, height: 48 });
win.add(button);
const avatar = Ti.UI.createView({ top: 160, width: 64, height: 64, borderRadius: 32, backgroundColor: '#6655dd' });
avatar.add(Ti.UI.createLabel({ text: 'JM', color: '#fff', font: { fontSize: 24, fontWeight: 'bold' } }));
win.add(avatar);
const toolbarButton = Ti.UI.createButton({ title: 'Toolbar source' });
win.add(Ti.UI.createToolbar({ top: 250, items: [toolbarButton] }));
const status = Ti.UI.createLabel({ text: 'Running…', top: 340, color: '#222', width: Ti.UI.FILL, textAlign: 'center' });
win.add(status);
const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL, layout: 'vertical' });
content.add(Ti.UI.createLabel({ text: 'Content survives rapid reopen', top: 20, height: 40, color: '#222' }));
const close = Ti.UI.createButton({ title: 'Close', top: 20, height: 48 });
content.add(close);
const popover = A.createPopover({ contentView: content, width: 300, height: 180, transition: 'zoom' });
close.addEventListener('click', () => popover.hide());
const sheet = A.createActionSheet({ title: 'Rapid confirmation', actions: [{ id: 'yes', title: 'Confirm' }] });
const sources = [toolbarButton, navButton, button, avatar];
const total = 40;
let cycle = 0, shows = 0, dismissals = 0, timer, finished = false;
function log(s) { Ti.API.info('ANCHORED_STRESS ' + s); status.text = s; }
function fail(s) { finished = true; clearTimeout(timer); log('FAIL ' + s); }
function next() {
    if (cycle === total) {
        finished = true;
        log('PASS ' + shows + ' shows/' + dismissals + ' dismissals, animated immediate reopen and early hide');
        popover.transition = 'zoom';
        toolbarButton.addEventListener('click', () => popover.show({ sourceView: toolbarButton }));
        navButton.addEventListener('click', () => popover.show({ sourceView: navButton }));
        button.addEventListener('click', () => popover.show({ sourceView: button }));
        avatar.addEventListener('click', () => popover.show({ sourceView: avatar }));
        return;
    }
    const proxy = cycle >= 32 ? sheet : popover;
    const source = sources[cycle % sources.length];
    if (proxy === popover) popover.transition = cycle < 16 ? 'zoom' : 'system';
    timer = setTimeout(() => fail('timeout at cycle ' + cycle), 6000);
    proxy.show({ sourceView: source });
    // Even cycles hide while opening; odd cycles hide immediately after show.
    if (cycle % 2 === 0) {
        proxy.hide();
        proxy.hide();
        proxy.show({ sourceView: source });
    }
}
function shown() {
    if (finished) return;
    shows++;
    if (cycle === 1 || cycle === 17) popover.setSourceView(toolbarButton);
    if (cycle === 3 || cycle === 19) popover.setSourceView(button);
    if (cycle === 11) avatar.hide();
    const proxy = cycle >= 32 ? sheet : popover;
    if (proxy === popover) proxy.setContentSize({ width: 300, height: 180 + (cycle % 3) * 20 });
    if (cycle % 2 !== 0) { proxy.hide(); proxy.hide(); proxy.show({ sourceView: sources[cycle % sources.length] }); }
}
function dismissed(e) {
    if (finished) return;
    clearTimeout(timer);
    if (e.reason !== 'programmatic') { fail('reason ' + e.reason); return; }
    dismissals++;
    if (cycle === 11) avatar.show();
    cycle++;
    if (shows !== dismissals) { fail('event mismatch ' + shows + '/' + dismissals); return; }
    // Reopen directly from the dismiss event, where the original race occurs.
    next();
}
popover.addEventListener('show', shown); sheet.addEventListener('show', shown);
popover.addEventListener('dismiss', dismissed); sheet.addEventListener('dismiss', dismissed);
win.addEventListener('open', () => setTimeout(() => {
    let rejected = 0;
    try { A.createPopover({ contentView: Ti.UI.createView(), transition: 'bad' }).show({ sourceView: button }); }
    catch (e) { if (String(e).includes('invalid_transition')) rejected++; }
    try { A.createActionSheet({ actions: [{ title: 'Confirm' }], transition: 'zoom' }).show({ sourceView: button }); }
    catch (e) { if (String(e).includes('unsupported_transition')) rejected++; }
    if (rejected !== 2) { fail('transition validation count ' + rejected); return; }
    Ti.API.info('ZOOM_CHECK transition validation PASS'); next();
}, 500));
nav.open();
