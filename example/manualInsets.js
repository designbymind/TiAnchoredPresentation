// Classic app Resources/app.js: header/footer overlays with explicit scroll insets.
const Anchored = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'Manual popover insets', backgroundColor: '#f4f4f7' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const source = Ti.UI.createButton({ title: 'Open table', top: 130, height: 48, width: 220 });
win.add(source);
const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL });
const table = Ti.UI.createTableView({ top: 0, bottom: 0, width: Ti.UI.FILL, sectionHeaderTopPadding: 0,
    data: Array.from({ length: 18 }, (_, i) => ({ title: 'Item ' + (i + 1) })) });
content.add(table);
const header = Ti.UI.createView({ top: 0, height: 52, width: Ti.UI.FILL, backgroundColor: '#77000000' });
header.add(Ti.UI.createLabel({ text: 'Custom Titanium content', color: '#fff' }));
content.add(header);
const footer = Ti.UI.createView({ bottom: 0, height: 80, width: Ti.UI.FILL, backgroundColor: '#fff' });
const resize = Ti.UI.createButton({ title: 'Resize', top: 0, height: 40 });
const close = Ti.UI.createButton({ title: 'Close', bottom: 0, height: 40 });
footer.add(resize); footer.add(close); content.add(footer);
const bubble = Anchored.createPopover({ contentView: content, width: 300, height: 360,
    transition: 'zoom', autoAdjustScrollViewInsets: false });
let expanded = false;
resize.addEventListener('click', () => {
    expanded = !expanded;
    bubble.setContentSize({ width: 300, height: expanded ? 440 : 360 });
});
close.addEventListener('click', () => bubble.hide());
bubble.addEventListener('show', () => {
    table.setContentInsets({ top: 52, bottom: 80, left: 0, right: 0 });
    table.setContentOffset({ x: 0, y: -52 }, { animated: false });
});
source.addEventListener('click', () => bubble.show({ sourceView: source }));
nav.open();
