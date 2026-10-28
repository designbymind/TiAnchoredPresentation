const Anchored = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'Native dimming', backgroundColor: '#f3f5fa' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const status = Ti.UI.createLabel({ top: 30, text: 'Tap a mode, then tap Help while open.', color: '#172238', height: 50 });
win.add(status);
const help = Ti.UI.createButton({ title: 'Help (pass-through)', top: 100, left: 24, width: 210, height: 50, backgroundColor: '#b3e5fc', borderRadius: 14 });
const overlapping = Ti.UI.createView({ top: 110, left: 210, width: 40, height: 30, backgroundColor: '#d9c4ff', borderRadius: 8, touchEnabled: false });
win.add(help);
win.add(overlapping);
const avatar = Ti.UI.createView({ top: 100, right: 24, width: 50, height: 50, backgroundColor: '#ffc4d4', borderRadius: 25 });
avatar.add(Ti.UI.createLabel({ text: 'JM', color: '#522438' }));
win.add(avatar);
let taps = 0;
help.addEventListener('click', () => { status.text = 'Help tapped ' + (++taps) + ' times'; });
const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL, layout: 'vertical' });
content.add(Ti.UI.createLabel({ text: 'UIKit still owns this bubble', color: '#172238', top: 22, height: 45 }));
const move = Ti.UI.createButton({ title: 'Move pass-through views', top: 14, height: 44 });
const close = Ti.UI.createButton({ title: 'Close', top: 14, height: 44 });
content.add(move);
content.add(close);
const bubble = Anchored.createPopover({ contentView: content, width: 300, height: 230, transition: 'zoom', dimmingOpacity: 0.35, passthroughViews: [help, overlapping, avatar] });
let moved = false;
move.addEventListener('click', () => {
    moved = !moved;
    help.animate({ left: moved ? 60 : 24, duration: 400 });
    overlapping.animate({ left: moved ? 246 : 210, duration: 400 });
});
close.addEventListener('click', () => bubble.hide());
['No dimming', 'Dim everything', 'Auto cutouts', 'Explicit shapes'].forEach((title, index) => {
    const button = Ti.UI.createButton({ title: title, top: 200 + index * 64, width: 260, height: 48 });
    button.addEventListener('click', () => {
        bubble.dimmingEnabled = index > 0;
        bubble.dimmingExcludesPassthroughViews = index >= 2;
        bubble.dimmingCutoutShapes = index === 3 ? [
            { view: help, shape: 'capsule' },
            { view: avatar, shape: 'circle' },
            { view: overlapping, shape: 'roundedRect', cornerRadius: 12 }
        ] : [];
        bubble.show({ sourceView: button });
    });
    win.add(button);
});
win.addEventListener('close', () => bubble.hide({ animated: false }));
nav.open();
