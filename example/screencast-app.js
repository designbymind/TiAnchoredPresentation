const Anchored = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'Anchored Presentations', backgroundColor: Ti.UI.userInterfaceStyle === 1 ? '#FFFFFF' : '#000000' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const clear = Ti.UI.createButton({ title: 'Confirm' });
const info = Ti.UI.createButton({ image: Ti.UI.iOS.systemImage('figure.teen', { weight: 'semibold', size: 20 }) });
win.setRightNavButtons([clear, info]);

const confirmation = Anchored.createActionSheet({
	title: 'Are you sure you want to delete all your recent items?',
	actions: [
		{ id: 'deleteAll', title: 'Yes, delete all', style: 'destructive' },
		{ id: 'cancel', title: 'Cancel', style: 'cancel' }
	]
});
confirmation.addEventListener('click', (e) => Ti.API.info('Action: ' + e.id));
confirmation.addEventListener('dismiss', (e) => Ti.API.info('Confirmation dismissed: ' + e.reason));
clear.addEventListener('click', () => confirmation.show({ sourceView: clear }));

function createContentView(getPopover) {
	const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL });
	const heading = Ti.UI.iOS.createBlurView({ zIndex: 1, effect: Ti.UI.iOS.BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL, width: Ti.UI.FILL, height: 52, top: 0 });
	heading.add(Ti.UI.createLabel({ text: 'Custom Titanium Content', top: 0, left: 16, width: Ti.UI.FILL, height: 52, textAlign: Ti.UI.TEXT_ALIGNMENT_LEFT, font: { fontSize: 18, fontWeight: 'bold' } }));
	content.add(heading);
	const list = Ti.UI.createTableView({
		top: 0,
		width: Ti.UI.FILL,
		height: Ti.UI.FILL,
		backgroundColor: 'transparent',
		separatorStyle: Ti.UI.TABLE_VIEW_SEPARATOR_STYLE_NONE,
		contentInsets: { top: 52, bottom: 52 },
		data: [
			{ title: 'First item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Second item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Third item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Fourth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Fifth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Sixth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Seventh item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Eighth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Ninth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Tenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Eleventh item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Twelth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Thirteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Fourteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Fifteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Sixteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Seventeenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Eighteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Ninteenth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' },
			{ title: 'Twentieth item', backgroundColor: 'transparent', backgroundSelectedColor: Ti.UI.userInterfaceStyle === 1 ? 'rgba(255, 255, 255, 0.8)' : 'rgba(0, 0, 0, 0.3)', color: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF', selectedColor: Ti.UI.userInterfaceStyle === 1 ? '#000000' : '#FFFFFF' }
		]
	});
	content.add(list);
	const footing = Ti.UI.iOS.createBlurView({ zIndex: 1, effect: Ti.UI.iOS.BLUR_EFFECT_STYLE_SYSTEM_ULTRA_THIN_MATERIAL, width: Ti.UI.FILL, height: 52, bottom: 0 });
	const larger = Ti.UI.createButton({ title: 'Resize', top: 0, left: 0, width: '50%', height: 52, font: { fontSize: 16, fontWeight: 'bold' } });
	const close = Ti.UI.createButton({ title: 'Close', top: 0, right: 0, width: '50%', height: 52, font: { fontSize: 16, fontWeight: 'bold' } });
	footing.add(larger);
	footing.add(close);
	content.add(footing);

	let expanded = false;
	larger.addEventListener('click', () => {
		expanded = !expanded;
		getPopover()?.setContentSize({ width: expanded ? Ti.Platform.displayCaps.platformWidth - 64 : 300, height: expanded ? Ti.Platform.displayCaps.platformHeight / 2 : 290 });
	});
	close.addEventListener('click', () => getPopover()?.hide());

	return content;
}

function createPopover(sourceView) {
	Ti.API.info('Creating popover for source view: ' + sourceView);
	var popover = Anchored.createPopover({ contentView: createContentView(() => popover), width: 300, height: 290, transition: 'zoom', autoAdjustScrollViewInsets: false });
	popover.addEventListener('show', (e) => {
		Ti.API.info('Popover source: ' + e.sourceKind);
	});
	popover.addEventListener('dismiss', (e) => {
		Ti.API.info('Popover dismissed: ' + e.reason);

		popover = null;
	});
	return popover;
}

info.addEventListener('click', () => createPopover(info).show({ sourceView: info }));

const button = Ti.UI.createButton({ title: 'Ti.UI.Button → Popover', top: 80, right: 32, width: 220, height: 48, backgroundColor: Ti.UI.userInterfaceStyle === 1 ? '#EFEFF4' : '#222222', borderRadius: 8 });
win.add(button);
button.addEventListener('click', () => {
	createPopover(button).show({ sourceView: button });
});
const card = Ti.UI.createView({ width: 260, height: 80, borderRadius: 18, backgroundColor: '#6655dd' });
card.add(Ti.UI.createLabel({ text: 'Ti.UI.View → Confirmation', color: '#fff' }));
win.add(card);
card.addEventListener('click', () => confirmation.show({ sourceView: card }));
// An ordinary view used as an avatar: no toolbar or navigation bar wrapper.
const avatar = Ti.UI.createImageView({ left: 32, bottom: 140, width: 64, height: 64, preventDefaultImage: true, scalingMode: Ti.UI.SCALING_ASPECT_FIT, borderRadius: 32, backgroundColor: Ti.UI.userInterfaceStyle === 1 ? '#EFEFF4' : '#222222', image: 'https://picsum.photos/300' });
win.add(avatar);
avatar.addEventListener('click', () => createPopover(avatar).show({ sourceView: avatar }));
const toolbarButton = Ti.UI.createButton({ title: 'Toolbar Popover' });
const toolbar = Ti.UI.createToolbar({ bottom: 34, items: [toolbarButton] });
win.add(toolbar);
toolbarButton.addEventListener('click', () => createPopover(toolbarButton).show({ sourceView: toolbarButton }));
nav.open();
