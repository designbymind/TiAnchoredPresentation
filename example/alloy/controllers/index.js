const Anchored = require('ti.anchoredpresentation');
const contentController = Alloy.createController('anchoredContent');
const popover = Anchored.createPopover({ contentView: contentController.getView(), width: 300, height: 290, transition: 'zoom' });
contentController.on('resize', e => popover.setContentSize({ width: e.width, height: e.height }));
contentController.on('requestClose', () => popover.hide());
const confirmation = Anchored.createActionSheet({
    title: 'Are you sure you want to delete all your recent items?',
    actions: [{ id: 'deleteAll', title: 'Yes, delete all', style: 'destructive' }]
});
confirmation.addEventListener('click', e => Ti.API.info('Action: ' + e.id));
confirmation.addEventListener('dismiss', e => Ti.API.info('Confirmation: ' + e.reason));
popover.addEventListener('dismiss', e => Ti.API.info('Popover: ' + e.reason));
const clear = Ti.UI.createButton({ title: 'Clear' });
const info = Ti.UI.createButton({ title: 'Info' });
$.win.setRightNavButtons([clear, info]);
clear.addEventListener('click', () => confirmation.show({ sourceView: clear }));
info.addEventListener('click', () => popover.show({ sourceView: info }));
const toolbarButton = Ti.UI.createButton({ title: 'Toolbar popover' });
$.win.add(Ti.UI.createToolbar({ bottom: 0, items: [toolbarButton] }));
toolbarButton.addEventListener('click', () => popover.show({ sourceView: toolbarButton }));
function showAvatar() { popover.show({ sourceView: $.avatar }); }
function showButton() { popover.show({ sourceView: $.button }); }
function showCard() { confirmation.show({ sourceView: $.card }); }
$.nav.addEventListener('close', () => {
    popover.hide({ animated: false });
    confirmation.hide({ animated: false });
    contentController.off();
    contentController.destroy();
    $.destroy();
});
$.nav.open();
