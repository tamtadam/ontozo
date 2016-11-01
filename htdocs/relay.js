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
    this.relays = new Object() ;
    this.connections = connections ;
    for( var relay_id in relays_data ){
        this.relays[ relay_id ] = new Relay( relays_data[ relay_id  ] ) ;
    }
}


function delete_connection( relay_id_p, remove_parent ){
	var relay_id ;
	var from ;
	
	if( typeof( relay_id_p ) == "string" ||
		typeof( relay_id_p ) == "number" ){
		relay_id = relay_id_p ;		

	} else {
		relay_id = this.id ;
		relay_id  = relay_id.replace( 'delete_connection', '' ) ;

	}

	var relay = G_RELAYS.get_relay_by_id( relay_id )   ;
	if ( relay && document.getElementById( "delete_connection" + relay.get_id() ) ){
		from = document.getElementById( "delete_connection" + relay.get_id() ).parentNode.id ;
		from = from.replace( '_connections', '' ) ;
	}

	if ( remove_parent ){
    	from = relay_id_p ;
    	G_RELAYS.connections[ from ] = [] ;
    } else {
    	for( var idx in G_RELAYS.connections[ from ] ){
    		if( G_RELAYS.connections[ from ][ idx ] == relay.get_id() ){
    			G_RELAYS.connections[ from ].splice( idx, 1 );
    			break ;
    		}
    	}
    	
    }
    push_cmd("delete_connection", JSON.stringify( 
    											  { 
    												"child"  : ( remove_parent == 0 ? relay.get_id() : null ),
    												"parent" : from 
    											  } ) ) ;
    processor( send_cmd() ) ;
    get_connections();
    G_RELAYS.print_connections( from, from + "_connections" );
}


Relays.prototype.add_new_relay = function( data ){
    var ret_val = new Object( { 'add_new_relay' : 1 } ) ;
    
    push_cmd( "add_new_relay", JSON.stringify( new Object( data ) ) ) ;
    ret_val = processor( send_cmd(), ret_val ) ;
    data    = ret_val[ 'add_new_relay' ]       ;

    if ( data.relay_id != null ){
        this.relays[ data.id ] = new Relay( data ) ;
        create_on_off_for_relay() ;
    } else {
        alert( "relay is not added" ) ;
    }    
    
}

Relays.prototype.get_relay_list_to_select_list = function(){
    var sel_rel = new Array();
    var cnt     = 0 ;
    for ( var relay in this.relays ){
        sel_rel[ cnt ]       = new Object();
        sel_rel[ cnt ].id    = this.relays[ relay ].get_id();
        sel_rel[ cnt ].title = this.relays[ relay ].get_name();
        cnt++ ;
    }
    return sel_rel ;
};

Relays.prototype.add_new_connections = function( from, to ){
    if( this.connections[ from ] == null ){
    	this.connections[ from ] = new Array() ;
    }

    this.connections[ from ].push( to ) ;
    push_cmd("add_new_connections", JSON.stringify( { "parent" : from, "child" : to } ) ) ;
    processor( send_cmd() ) ;
}

function get_connections(async_){
    var ret_val = new Object( { 'get_connections' : 1 } ) ;
    push_cmd( "get_connections", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    ret_val = processor( send_cmd(async_), ret_val ) ;
    CONNECTIONS = ret_val[ 'get_connections' ] ;
}

function get_relay_list(async_){
    var ret_val = new Object( { 'get_relay_list' : 1 } ) ;
    push_cmd( "get_relay_list", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    ret_val = processor( send_cmd(async_), ret_val ) ;
    RELAYS = ret_val[ 'get_relay_list' ] ;
}


Relays.prototype.print_connections = function( relay_id, html_id ){
    var p = document.getElementById( html_id ) ;
    p.innerHTML =  "" ;
    for( var idx in this.connections[ relay_id ] ){
    		relay = G_RELAYS.get_relay_by_id( this.connections[ relay_id ][ idx ] ) ;
    		h1 = create_h4( relay.get_name() ) ;
    		h1.innerHTML = relay.get_name();
    		remove_btn = create_button_as_img( "delete_connection" +  relay.get_id(), delete_connection, "delete", "img/clear.png" ) ;
    		p.appendChild( h1 );
    		p.appendChild( remove_btn );
	}
}

Relays.prototype.get_relay_id_by_name = function( name ){
    for ( var idx in this.relays ){
        if( this.relays[ idx ].get_name() == name ){
            return this.relays[ idx ].get_id() ;
        }
    }
}

Relays.prototype.get_relay_by_id = function( id ){
    for ( var idx in this.relays ){
        if( this.relays[ idx ].get_id() == id ){
            return this.relays[ idx ] ;
        }
    }
}

Relays.prototype.get_relays_to_acomplete = function( rel_id ){
    var relay_list = new Array();
    var cnt        = 0 ;
    for ( var idx in this.relays ){
        if( this.relays[ idx ].get_id() != rel_id ){

            relay_list[ cnt ] = new Object();
            relay_list[ cnt ].name  = this.relays[ idx ].get_id() ;
            relay_list[ cnt ].label = this.relays[ idx ].get_name() ;
            cnt++ ;
        }
    }
    return relay_list ;
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

        var ret_val = new Object( { 'save_relay_data_to_db' : 1 } ) ;
        
        push_cmd("save_relay_data_to_db", JSON.stringify( save_data ) ) ;
	    ret_val = processor( send_cmd(), ret_val) ;

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
    var relay_id  = this.id ;

    relay_id  = relay_id.replace( 'save_relay_data', '' ) ;
    var relay = G_RELAYS.get_relay_by_id( relay_id ) ;
    
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
    
    if( document.getElementById( relay_id + "_p" ) ){
        document.getElementById( relay_id + "_p" ).innerHTML = document.getElementById( relay_id + "_p" ).innerHTML.replace( /\w+/, relay.get_name() ) ;
    }
}

function delete_relay(){
	var relay_id = this.id ;
    relay_id  = relay_id.replace( 'delete_relay', '' ) ;
    var relay = G_RELAYS.get_relay_by_id( relay_id )   ;

    removerelay_from_program( relay.get_id() ) ;

    relay.delete_it() ;
    get_relay_list() ;
    get_relays_in_programs() ;
    get_connections();

    G_RELAYS = new Relays( RELAYS, CONNECTIONS );
    //TODO
    delete_connection( relay_id, 1 );
    print_available_relays() ;
    create_on_off_for_relay();	
}

function create_on_off_for_relay(){
    var manual_control = document.getElementById( "manual_control" ) ;
    manual_control.innerHTML = '' ;
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

        ip.value       = relay.get_ip() ;
        name.value     = relay.get_name() ;
        position.value = relay.get_pos() ;

        save_na      = create_button_as_img( "save_relay_data" +  relay.get_id(), save_relay_data, "add", "img/save.png" ) ;
        delete_rel   = create_button_as_img( "delete_relay" +  relay.get_id(), delete_relay, "delete", "img/clear.png" ) ;
    	/*row_id = add_row_to_table( "on_off", {
			"id"   : "row_" + relay.get_id() ,
			"name" : relay.get_name() ,
			"btn_list" : [ on, on_label, off, off_label, 
			               document.createElement( 'br' ), document.createTextNode( "ip:" ), ip ,
			               document.createElement( 'br' ), document.createTextNode( "name:" ), name ,
			               document.createElement( 'br' ), document.createTextNode( "position:" ), position ,
			               document.createElement( 'br' ), document.createTextNode( "kapcsoló relay:" ), auto ,
			               p,save_na,
			               delete_rel,
			               document.createElement( 'br' )
			]
    	} ) ;*/
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
    	list_div.appendChild(document.createTextNode( "kapcsoló relay:" ));
    	list_div.appendChild(auto);
    	list_div.appendChild(p);
    	list_div.appendChild(save_na);
    	list_div.appendChild(delete_rel);
    	manual_control.appendChild(list_head);
    	manual_control.appendChild(list_div);
        G_RELAYS.print_connections( relay.get_id(), relay.get_id() + "_connections" );

        $( "#" + on_input.id ).button().click(function() {
	        var relay = G_RELAYS.get_relay_by_id( this.name ) ;
	        relay.set_status( execution.START ) ;
	    });

	    $( "#" + off_input.id ).button().click(function() {
            var relay = G_RELAYS.get_relay_by_id( this.name ) ;
            relay.set_status( execution.STOP ) ;
        });

        $("#" + auto.id ).autocomplete({
	        source: relay_autocomplete,
	        select: function(event, ui) {
			    var relay_id  = this.id ;
			    relay_id  = relay_id.replace( 'auto_', '' ) ;
			    G_RELAYS.add_new_connections( relay_id, G_RELAYS.get_relay_id_by_name( ui.item.value ) ) ;
			    G_RELAYS.print_connections( relay_id, relay_id + "_connections" ) ;
	        },
	    });

    }
    if( accordion_mc == null ) {
    	accordion_mc = $( "#manual_control" ).accordion({
    		collapsible: true
    	});
    } else {
    	accordion_mc.accordion( "destroy" );
    	accordion_mc = $( "#manual_control" ).accordion({
    		collapsible: true
    	});
    }

}
