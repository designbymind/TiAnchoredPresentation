const Anchored = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'Anchored presentations', backgroundColor: '#f4f4f7' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const clear = Ti.UI.createButton({ title: 'Clear' });
const info = Ti.UI.createButton({ title: 'Info' });
win.setRightNavButtons([clear, info]);

const confirmation = Anchored.createActionSheet({
    title: 'Are you sure you want to delete all your recent items?',
    actions: [
        { id: 'deleteAll', title: 'Yes, delete all', style: 'destructive' },
        { id: 'cancel', title: 'Cancel', style: 'cancel' }
    ]
});
confirmation.addEventListener('click', e => Ti.API.info('Action: ' + e.id));
confirmation.addEventListener('dismiss', e => Ti.API.info('Confirmation dismissed: ' + e.reason));
clear.addEventListener('click', () => confirmation.show({ sourceView: clear }));

const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL, layout: 'vertical' });
content.add(Ti.UI.createLabel({ text: 'Custom Titanium content', top: 20, height: 30, color: '#222' }));
const list = Ti.UI.createTableView({ top: 12, height: 110,
    data: [{ title: 'First item' }, { title: 'Second item' }, { title: 'Third item' }] });
content.add(list);
const larger = Ti.UI.createButton({ title: 'Resize popover', top: 10, height: 40 });
const close = Ti.UI.createButton({ title: 'Close', top: 5, height: 40 });
content.add(larger);
content.add(close);
const popover = Anchored.createPopover({ contentView: content, width: 300, height: 290, transition: 'zoom' });
let expanded = false;
larger.addEventListener('click', () => {
    expanded = !expanded;
    popover.setContentSize({ width: 300, height: expanded ? 380 : 290 });
});
close.addEventListener('click', () => popover.hide());
popover.addEventListener('show', e => Ti.API.info('Popover source: ' + e.sourceKind));
popover.addEventListener('dismiss', e => Ti.API.info('Popover dismissed: ' + e.reason));
info.addEventListener('click', () => popover.show({ sourceView: info }));

const button = Ti.UI.createButton({ title: 'Normal button → popover', top: 100, height: 48 });
win.add(button);
button.addEventListener('click', () => popover.show({ sourceView: button }));
const card = Ti.UI.createView({ top: 180, width: 260, height: 80, borderRadius: 18, backgroundColor: '#6655dd' });
card.add(Ti.UI.createLabel({ text: 'Normal view → confirmation', color: '#fff' }));
win.add(card);
card.addEventListener('click', () => confirmation.show({ sourceView: card }));
// An ordinary view used as an avatar: no toolbar or navigation bar wrapper.
const avatar = Ti.UI.createView({ left: 24, top: 290, width: 64, height: 64,
    borderRadius: 32, backgroundColor: '#6655dd' });
avatar.add(Ti.UI.createLabel({ text: 'JM', color: '#fff', font: { fontSize: 24, fontWeight: 'bold' } }));
win.add(avatar);
avatar.addEventListener('click', () => popover.show({ sourceView: avatar }));
const toolbarButton = Ti.UI.createButton({ title: 'Toolbar popover' });
const toolbar = Ti.UI.createToolbar({ bottom: 0, items: [toolbarButton] });
win.add(toolbar);
toolbarButton.addEventListener('click', () => popover.show({ sourceView: toolbarButton }));
win.add(Ti.UI.createLabel({ bottom: 85, text: 'iOS 26+ system appearance' }));
nav.open();
