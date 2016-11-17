function create_div( divdata ) {
    var div   = document.createElement("div");
    div.id    = divdata[ "id" ];
    div.style = divdata[ "style" ];
    return div;
}

function create_p( id ) {
    var div = document.createElement("p");
    div.id  = id ;
    return div;
}


function create_h1( id ) {
    var p = document.createElement("h1");
    p.id = id;
    return p;
}

function create_h2( id ) {
    var p = document.createElement("h2");
    p.id = id;
    return p;
}


function create_h3( id ) {
    var p = document.createElement("h3");
    p.id = id;
    return p;
}

function create_h4( id ) {
    var p = document.createElement("h4");
    p.id = id;
    return p;
}

function create_h5( id ) {
    var p = document.createElement("h5");
    p.id = id;
    return p;
}
function create_h6( id ) {
    var p = document.createElement("h6");
    p.id = id;
    return p;
}
function create_button(id, func, label) {
    var button = document.getElementById(id);
    if (button == null) {
        button = document.createElement('button');
        button.name = name;
        button.id = id;
    }
    button.onclick = func;
    button.value = label;
    return button;
}

function create_button_as_img(id, func, label, src) {
    var button = document.getElementById(id);
    if (button == null) {
        button = document.createElement('img');
        if (id) {
            button.id = id;
        }
    }
    if (button.src == "") {
        button.src = src;
    }
    button.onclick = func  ;
    button.value   = label ;
    return button;
}

function create_select_list_fea(name, id, list, func) {
    var sel;
    var i = 0;
    sel = document.getElementById(id);
    if (sel == null) {
        sel = document.createElement('select');
        sel.name = name;
        sel.id = id;
    } else {
        document.getElementById(id).innerHTML = "";
    }

    sel.onclick = func;

    for (var idx in list) {
        sel.options[i]       = new Option( list[ idx ][ 'title' ], list[ idx ][ 'title' ] );
        sel.options[i].value = list[ idx ][ 'id' ];
        sel.options[i].id    = list[ idx ][ 'id' ];

        i++;
    }

    sel.multiple = "multiple";
    return sel;
}

function create_input( in_data ){
    var input = document.getElementById( in_data.id );

    if (input == null) {
        input = document.createElement('input');
    }

    input.id      = in_data.id ;
    input.type    = in_data.type ;
    input.name    = in_data.name ;
    if ( in_data.checked == "checked" ){
    	input.checked = "checked" ;
    }
    return input ;
}

function create_label( label_input ){
    var label = document.createElement( 'label' );
    label.setAttribute( "for", label_input[ "for" ] ) ;
    label.innerHTML = label_input[ "html" ] ;
    return label ;
}

String.prototype.toHHMMSS = function () {
    var sec_num = parseInt(this, 10); // don't forget the second param
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);

    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    var time    = hours+':'+minutes+':'+seconds;
    return time;
}

function remove_by_id(id) {
    return (elem = document.getElementById(id)).parentNode.removeChild(elem);
}

String.prototype.toHHMM = function () {
    var sec_num = parseInt(this, 10); // don't forget the second param
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);

    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    var time    = hours+':'+minutes;
    return time;
}

function create_table(table_id, table_data){
    var table = document.createElement("table");
    var header = table.createTHead();
    var row = header.insertRow(0);

    for( var cell_cnt = 0; cell_cnt < table_data['headers'].length; cell_cnt++ ){
        cell1 = row.insertCell(cell_cnt);
        cell1.appendChild( table_data['headers'][ cell_cnt ] );
    }
    table.id = id;
    return table;
}

function add_row_to_table(table_id, row_item) {
    var row;
    var cell1;
    var cell2;
    var table = document.getElementById(table_id);
    var last_row_idx;

    if (table == null) {
        return false;
    }

    last_row_idx = get_last_row_idx_from_table(table_id);
    row = table.insertRow(last_row_idx);

    row.setAttribute("id", row_item[ 'id' ]);
    row.setAttribute("name", row_item[ 'name' ] );

    row.id = last_row_idx;

    if (row_item['row_ondblclick']) {
        row.ondblclick = row_item['row_ondblclick'];
    }
    if (row_item['row_onclick']) {
        row.ondblclick = row_item['row_onclick'];
    }

    cell1 = row.insertCell(0);
    cell1.innerHTML = row_item['id'] + row_item['name'];

    for (var i in row_item['btn_list']) {
        cell1.appendChild(row_item['btn_list'][i]);
    }

    return row.id;
}

function get_last_row_idx_from_table(table_id) {
    var table = document.getElementById(table_id);
    if (table) {
        return table.rows.length;
    } else {
        return -1;
    }
}

function get_act_row_idx_from_table(table_id) {
    var table = document.getElementById(table_id);
    if (table) {
        return table.rowIndex;
    } else {
        return -1;
    }
}

function remove_by_id(id) {
	if ( document.getElementById(id) ){
		return (elem = document.getElementById(id)).parentNode.removeChild(elem);		
	}
}
