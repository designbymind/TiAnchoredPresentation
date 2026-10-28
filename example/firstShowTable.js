// Classic regression example. Compare the first opening and repeated fresh bubbles.
// The grouped table header is 92 points high; rows should follow without an extra gap.
const Anchored = require('ti.anchoredpresentation');
const win = Ti.UI.createWindow({ title: 'First-show TableView regression', backgroundColor: '#eeeeee' });
const nav = Ti.UI.createNavigationWindow({ window: win });
const source = Ti.UI.createButton({ title: 'New table bubble', top: 130, width: 220, height: 48 });
win.add(source);
let count = 0;
function openBubble() {
    count++;
    const content = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.FILL });
    const header = Ti.UI.createView({ width: Ti.UI.FILL, height: Ti.UI.SIZE });
    const heading = Ti.UI.createView({ width: Ti.UI.FILL, height: 52, top: 24, bottom:16 });
    heading.add(Ti.UI.createLabel({ text: 'First-show regression ' + count, left:24, height:30, top:8 }));
    header.add(heading);
    const section = Ti.UI.createTableViewSection();
    ['Visibility','Created at','Expires at','Who can reply','Views'].forEach(title => section.add(Ti.UI.createTableViewRow({title,height:48})));
    const footer = Ti.UI.createView({width:Ti.UI.FILL,height:48});
    footer.add(Ti.UI.createButton({title:'Footer actions',height:48}));
    const table = Ti.UI.createTableView({ width: Ti.UI.FILL, height: Ti.UI.FILL, top:0,
        style:Ti.UI.iOS.TableViewStyle.INSET_GROUPED, headerView: header, footerView:footer,
        sectionHeaderTopPadding:0, minRowHeight:48, tableSeparatorInsets:{left:0,right:0}, data:[section] });
    content.add(table);
    const close = Ti.UI.createButton({title:'Close',top:0,right:0,width:68,height:44});content.add(close);
    const popover = Anchored.createPopover({contentView:content,width:368,height:422,transition:'zoom',autoAdjustScrollViewInsets:true,arrowDirections:8});
    close.addEventListener('click',()=>popover.hide());
    popover.addEventListener('show',()=>Ti.API.info('FIRST_SHOW_TITANIUM '+count));
    popover.addEventListener('dismiss',()=>{table.data=[];content.removeAllChildren();});
    popover.show({sourceView:source});
}
source.addEventListener('click',openBubble);
win.addEventListener('open',()=>setTimeout(openBubble,500));
nav.open();
