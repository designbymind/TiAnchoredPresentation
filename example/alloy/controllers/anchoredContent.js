let expanded = false;
function resize() {
    expanded = !expanded;
    $.trigger('resize', { width: 300, height: expanded ? 380 : 290 });
}
function close() { $.trigger('requestClose'); }
