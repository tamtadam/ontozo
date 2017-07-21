var RELAYS;
var CONNECTIONS;
var accordion_mc = null;
// = {
//              "egy" : {
//                "ip"     : "1.1.1.1",
//                "status" : 0        ,
//                "id"     : "egy_id" ,
//                "name"   : "egy"    ,
//                "pos"    : 1        ,
//
//              },
//              "ketto" : {
//                "ip"     : "1.1.1.1",
//                "status" : 0        ,
//                "id"     : "ketto"  ,
//                "name"   : "ketto"  ,
//                "pos"    : 2        ,
//                "programs" :
//                           {
//                               "prog_1" :
//                                   {
//                                   "start" : 100 ,
//                                   "stop"  : 500 ,
//                                   }
//
//                           },
//              },
//              "harom" : {
//                "ip"     : "1.1.1.1",
//                "status" : 0        ,
//                "id"     : "harom"  ,
//                "name"   : "harom"  ,
//                "pos"    : 3        ,
//                "programs" :
//                           {
//                               "prog_1" :
//                                   {
//                                   "start" : 100 ,
//                                   "stop"  : 500 ,
//                                   }
//
//                           },
//              },
//              "negy" : {
//                "ip"     : "1.1.1.1",
//                "status" : 0        ,
//                "id"     : "negy"   ,
//                "name"   : "negy"   ,
//                "pos"    : 4,
//                "programs" :
//                           {
//                               "prog_1" :
//                                   {
//                                   "start" : 100 ,
//                                   "stop"  : 500 ,
//                                   }
//
//                           },
//              }};
///


function Relays ( relays_data, connections ) {
	_this = this;
	_this.connections = connections ;
	_this.relays = $.map( relays_data, function( relay_data, relay_id ){
    	return new Relay( relay_data ) ;
    }) ;
}


function delete_connection( connected_relay, parent_relay ){
    push_cmd("delete_connection", JSON.stringify(
    											  {
    												"child"  : ( connected_relay != null ? connected_relay.get_id() : null ),
    												"parent" : ( parent_relay    != null ? parent_relay.get_id()    : null ),
    											  } ) ) ;
    processor( send_cmd() ) ;
    G_RELAYS.connections= get_connections();
}


Relays.prototype.add_new_relay = function( data ){
    push_cmd( "add_new_relay", JSON.stringify( new Object( data ) ) ) ;
    ret_val = processor( send_cmd() ) ;
    data    = ret_val[ 'add_new_relay' ]       ;

    if ( data.relay_id != null ){
        this.relays.push( new Relay( data ) ) ;
        create_on_off_for_relay() ;
    } else {
        alert( "relay is not added" ) ;
    }

}

Relays.prototype.get_relay_list_to_select_list = function(){
    return $.map( this.relays, function( relay, index ) {
    	return { id : relay.get_id(), title : relay.get_name(), data : relay };
    } ) ;
};

Relays.prototype.add_new_connections = function( from, to ){
    push_cmd("add_new_connections", JSON.stringify( { "parent" : from, "child" : to } ) ) ;
    processor( send_cmd() ) ;
    this.connections = get_connections();
}

function get_connections(async_){
    push_cmd( "get_connections", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    var ret_val = processor( send_cmd(async_) ) ;
    CONNECTIONS = ret_val[ 'get_connections' ] ;
    return CONNECTIONS;
}

function get_relay_list(async_){
    push_cmd( "get_relay_list", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    var ret_val = processor( send_cmd(async_) ) ;
    RELAYS = ret_val[ 'get_relay_list' ] ;
}


Relays.prototype.print_connections = function( relay, html_id ){
    var p = $( '#' + html_id ) ;
    p.html("") ;
    for( var idx in this.connections[ relay.get_id() ] ){
    	var connected_relay = G_RELAYS.get_relay_by_id( this.connections[ relay.get_id() ][ idx ] );
		h1 = create_h4( 'connected_' + connected_relay.get_id() ) ;
		h1.innerHTML = connected_relay.get_name();
		
		remove_btn = create_button_as_img( null, function(){
			delete_connection( $( this ).data( 'data' ), $(this).parent().parent().data( 'data' ) );
		    G_RELAYS.print_connections( $(this).parent().parent().data( 'data' ), $(this).parent().parent().data( 'data' ).get_id() + "_connections" );
		}, "delete", "img/clear.png" ) ;
		
		$( remove_btn ).data('data', connected_relay);
		p.append( h1 );
		p.append( remove_btn );
    }
}

Relays.prototype.get_relay_id_by_name = function( name ){
	return this.relays.find( function( relay ){
		return relay.get_name() == name
	}).get_id();
}

Relays.prototype.get_relay_by_id = function( id ){
	return this.relays.find( function( relay ){
		return relay.get_id() == id
	})
}

Relays.prototype.get_relay_by_name = function( name ){
	return this.relays.find( function( relay ){
		return relay.get_name() == name
	})
}

Relays.prototype.get_relays_to_acomplete = function( rel_id ){
	var _this = this;

    return $.map(
    	$.grep( _this.relays,
		function( relay, index ){
    		return relay.get_id() != rel_id
    	}),
    	function( relay, index ){
    		return {  name : relay.get_name(), label : relay.get_name() }
    });
} ;

function Relay( relay_data ){
    console.log( relay_data )          ;
    this.ip     = relay_data['ip']     ;
    this.status = relay_data['run_status_id'] ;
    this.id     = relay_data['relay_id'] ;
    this.name   = relay_data['name']   ;
    this.pos    = relay_data['pos']    ;
    this.connected = relay_data['connected'];

    this.get_id = function(){
        return this.id ;
    } ;

    this.get_connected = function(){
        return this.connected ;
    } ;

    this.set_id = function( id ){
        this.id = id ;
    } ;

    this.get_id = function(){
        return this.id ;
    } ;

    this.set_ip = function( ip ){
        if ( this.save_relay_data_to_db( { 'ip' : ip } ) ){
            this.ip = ip ;
        } else {
            alert ( "ip is not saved" ) ;
        }
    } ;

    this.get_ip = function(){
        return this.ip ;
    } ;

    this.set_status = function( status ){
        if ( this.save_relay_data_to_db( { 'status' : status } ) ){
            this.status = status ;
        } else {
            alert ( "status is not saved" ) ;
        }
    } ;

    this.get_status = function(){
        return this.status ;
    } ;

    this.set_name = function( name ){
        if ( this.save_relay_data_to_db( { 'name' : name } ) ){
            this.name = name ;
        } else {
            alert ( "name is not saved" ) ;
        }
    } ;

    this.get_name = function(){
        return this.name ;
    } ;

    this.get_pos = function(){
        return this.pos ;
    } ;

    this.set_pos = function( pos ){
        if ( this.save_relay_data_to_db( { 'pos' : pos } ) ){
            this.pos = pos ;
        } else {
            alert ( "pos is not saved" ) ;
        }
    } ;
    this.delete_it = function(){
        push_cmd("delete_relay_from_program", JSON.stringify( { "relay_id" : this.get_id(), "order" : 1 } ) ) ;
        push_cmd("delete_relay",              JSON.stringify( { "relay_id" : this.get_id(), "order" : 2 } ) ) ;
	    processor( send_cmd() ) ;
    };

    this.save_relay_data_to_db = function( save_data ){
        save_data.id = this.get_id() ;
    	msg();
        push_cmd("save_relay_data_to_db", JSON.stringify( save_data ) ) ;
	    var ret_val = processor( send_cmd() ) ;

	    if ( ret_val[ 'save_relay_data_to_db' ] ){
            return true ;
	    } else {
            return false ;
	    }
    }
}
// TODO
function remove_rel_from_prog( slider, prog ){
    console.log( slider, prog ) ;
    if( RELAYS[ slider ][ prog ] != null ){
        delete RELAYS[ slider ][ prog ] ;
        console.log( RELAYS );
    } else {
        return null ;
    }
}

function save_relay_data(){
    var relay = $( this ).data( 'data' ) ;
	var relay_id  = relay.get_id() ;

    var value = $("#name_" + relay_id ).val() ;
    if ( value && relay.get_name() != value ){
        relay.set_name( value ) ;
    }

    value = $("#ip_" + relay_id ).val() ;
    if ( value && relay.get_ip() != value ){
        relay.set_ip( value ) ;
    }

    value = $("#pos_" + relay_id ).val() ;
    if ( value && relay.get_pos() != value ){
        relay.set_pos( value ) ;
    }

    print_available_relays() ;
}

function delete_relay( relay ){
    delete_connection( relay );
    relay.delete_it() ;

    get_relay_list() ;
    get_relays_in_programs() ;
    get_connections();

    G_RELAYS = new Relays( RELAYS, CONNECTIONS );

    print_available_relays() ;
    create_on_off_for_relay();	
}

function create_on_off_for_relay(){
    var manual_control = $( "#manual_control" ) ;
    manual_control.html('') ;
    var on_input  = new Object( {
        'id'      : "on"    ,
        'type'    : "radio" ,
        'name'    : null    ,
        'checked' : ""      ,
    } ) ;

    var off_input = new Object( {
        'id'      : "off"      ,
        'type'    : "radio"   ,
        'name'    : null      ,
        'checked' : "checked" ,
    } ) ;

    var on_label  = new Object( { "for" : "on" } ) ;
    var off_label = new Object( { "for" : "off" } ) ;

    var on  ;
    var off ;
    var relay ;
    var ip ;
    var position ;
    var save ;
    var name ;
    var save_na ;
    var connected_relays ;
    var auto ;
    var row_id ;
    var delete_rel ;

    for( var idx in G_RELAYS.relays ){
        relay = G_RELAYS.relays[ idx ] ;

        var list_head = create_h3( relay.get_name() + "not_used");
        list_head.innerHTML = relay.get_name() ;

        var list_div = create_div( {id : relay.get_name()} );
        $( list_div ).data('data', relay);

        if( relay.get_connected() == 1 ) {
        	list_div.style.backgroundColor = '#e6ffe6';
        } else {
        	list_div.style.backgroundColor = '#ffebe6';
        }

        on_input  = new Object( {
            'type'    : "radio" ,
            'checked' : false   ,
        } ) ;


    	off_input = new Object( {
            'type'    : "radio"   ,
            'checked' : false     ,
        } ) ;

        var relay_autocomplete = G_RELAYS.get_relays_to_acomplete( relay.get_id() ) ;
        var p          = create_h6( relay.get_id() + "_connections" ) ;
        on_input.id    = "on_"  + relay.get_id() ;
        off_input.id   = "off_" + relay.get_id() ;
        on_input.name  = relay.get_id() ;
        off_input.name = relay.get_id() ;

        if( relay.get_status() == execution.START ){
            on_input.checked = "checked" ;
        } else {
            off_input.checked = "checked" ;
        }

        on  = create_input( on_input )   ;
        off = create_input( off_input ) ;

        on_label  = create_label( { "for" : "on_"  + relay.get_id() , "html" : "ON"  } ) ;
        off_label = create_label( { "for" : "off_" + relay.get_id() , "html" : "OFF" } ) ;

        ip = create_input( {
                            "id"   : "ip_" + relay.get_id() ,
                            "name" : "ip_" + relay.get_id() ,
                            "type" : "input"
                       } ) ;

        name = create_input( {
                            "id"   : "name_" + relay.get_id() ,
                            "name" : "name_" + relay.get_id() ,
                            "type" : "input"
                       } ) ;

        position = create_input( {
                            "id"   : "pos_" + relay.get_id() ,
                            "name" : "pos_" + relay.get_id() ,
                            "type" : "input"
                       } ) ;

        auto = create_input( {
                            "id"   : "auto_" + relay.get_id(),
                            "name" : "auto_" + relay.get_id(),
                            "type" : "input"
                       } ) ;
        $( auto ).data('data', relay);
    	$( off_input ).data('data', relay);
        $( on_input ).data('data', relay);

        ip.value       = relay.get_ip() ;
        name.value     = relay.get_name() ;
        position.value = relay.get_pos() ;

        save_na      = create_button_as_img( "save_relay_data" +  relay.get_id(), save_relay_data, "add", "img/save.png" ) ;
        $( save_na ).data( 'data', relay );
        delete_rel   = create_button_as_img( "delete_relay" +  relay.get_id(), function(){
        	var relay = $( this ).data( 'data' );
        	delete_relay( relay );
        }, "delete", "img/clear.png" ) ;
        $( delete_rel ).data( 'data', relay );

    	list_div.appendChild(on);
    	list_div.appendChild(on_label);
    	list_div.appendChild(off);
    	list_div.appendChild(off_label);
    	list_div.appendChild(document.createElement( 'br' ));
    	list_div.appendChild(document.createTextNode( "ip:" ));
    	list_div.appendChild(ip);
    	list_div.appendChild(document.createElement( 'br' ));
    	list_div.appendChild(document.createTextNode( "name:" ));
    	list_div.appendChild(name);
    	list_div.appendChild(document.createElement( 'br' ));
    	list_div.appendChild(document.createTextNode( "position:" ));
    	list_div.appendChild(position);
    	list_div.appendChild(document.createElement( 'br' ));
    	list_div.appendChild(document.createTextNode( "mester relay:" ));
    	list_div.appendChild(auto);
    	list_div.appendChild(p);
    	list_div.appendChild(save_na);
    	list_div.appendChild(delete_rel);
    	manual_control.append(list_head);
    	manual_control.append(list_div);
        G_RELAYS.print_connections( relay, relay.get_id() + "_connections" );

        $( "#" + on_input.id ).button().click(function() {
	        var relay = $( this ).parent().data( 'data' ) ;
	        relay.set_status( execution.START ) ;
	    });

	    $( "#" + off_input.id ).button().click(function() {
            var relay = $( this ).parent().data( 'data' ) ;
            relay.set_status( execution.STOP ) ;
        });

        $("#" + auto.id ).autocomplete({
	        source: relay_autocomplete,
	        select: function(event, ui) {
	        	var relay     = $( this ).data( 'data' ) ;
			    var relay_id  = relay.get_id() ;
			    G_RELAYS.add_new_connections( relay_id, G_RELAYS.get_relay_id_by_name( ui.item.value ) ) ;
			    G_RELAYS.print_connections( relay, relay.get_id() + "_connections" ) ;
	        },
	    });
    }
    if( accordion_mc == null ) {
    	accordion_mc = $( "#manual_control" ).accordion({
    		collapsible: true,
    		heightStyle: "content"
    	});
    } else {
    	accordion_mc.accordion( "destroy" );
    	accordion_mc = $( "#manual_control" ).accordion({
    		heightStyle: "content",
    		collapsible: true
    	});
    }

}
