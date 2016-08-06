function Relay_in_program( relay_data ){
    this.relay_id         = relay_data['relay_id']     ;
    this.program_id       = relay_data['program_id'] ;
    this.start            = relay_data['start'] ;
    this.stop             = relay_data['stop']   ;
    this.program_relay_id = relay_data['program_relay_id']   ;

    this.get_program_relay_id = function(){
        return this.program_relay_id ;
    };

    this.get_relay_id = function(){
        return this.relay_id ;
    };

    this.get_program_id = function(){
        return this.program_id ;    
    };
    this.get_start = function(){
        return this.start ;
    };
    this.get_stop = function(){
        return this.stop ;    
    };
    this.set_stop = function( stop ){
        if ( this.save_data_to_db( { 'stop' : stop, 'program_id' : this.get_program_id(), 'relay_id' : this.get_relay_id(), 'program_relay_id' : this.get_program_relay_id() } ) ){
            this.stop = stop ;
        } else {
            alert ( "stop is not saved" ) ; 
        }   
    };
    this.set_start = function( start ){
        if ( this.save_data_to_db( { 'start' : start, 'program_id' : this.get_program_id(), 'relay_id' : this.get_relay_id(), 'program_relay_id' : this.get_program_relay_id() } ) ){
            this.start = start ;
        } else {
            alert ( "start is not saved" ) ; 
        }   
    }; 
    this.remove_relay_in_program = function(){
        var ret_val = new Object( { 'remove_relay_in_program' : 1 } ) ;
        
        push_cmd("remove_relay_in_program", JSON.stringify( {
        	'program_id' : this.get_program_id(), 
        	'relay_id' : this.get_relay_id()
        } ) ) ;
        ret_val = processor( send_cmd(), ret_val) ;
    }
    this.save_data_to_db = function( save_data ){
        var ret_val = new Object( { 'update_relay_prog_data_to_db' : 1 } ) ;
        
        push_cmd("update_relay_prog_data_to_db", JSON.stringify( save_data ) ) ;
        ret_val = processor( send_cmd( ASYNC ), ret_val ) ;

        if ( ret_val[ 'update_relay_prog_data_to_db' ] ){
            return true ;
        } else {
            return false ;
        }  
    }
};

function get_relays_in_programs(){
    var ret_val = new Object( { 'get_relays_in_programs' : 1 } ) ;
    push_cmd( "get_relays_in_programs", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    ret_val = processor( send_cmd(), ret_val ) ;
    if( ret_val[ 'get_relays_in_programs' ] ){
    	for( var i = 0; i < ret_val[ 'get_relays_in_programs' ].length; i++ ){
    		G_RELAYS_IN_PROGRAM[ i ] = new Relay_in_program( ret_val[ 'get_relays_in_programs' ][ i ] ) ;
    	}
    }
}

function removerelay_from_program( id ){
	var relay_id ;
	if ( typeof( id ) == "string" ){
		relay_id = id ;
	} else {
		relay_id = this.id ;
		relay_id = relay_id.replace( '_btn', '' );
	}

    var selected_prog  = $("#program_list").children(":selected").attr("id");

    var relay = G_RELAYS.get_relay_by_id( relay_id ) ;
    remove_by_id( relay_id + "_relay" ) ;
    var i ;
    for( i = 0; i < G_RELAYS_IN_PROGRAM.length; i++ ){
    	if( G_RELAYS_IN_PROGRAM[ i ].get_relay_id() == relay_id &&
        	G_RELAYS_IN_PROGRAM[ i ].get_program_id() == selected_prog	){
    		G_RELAYS_IN_PROGRAM[ i ].remove_relay_in_program();
    		break ;
    	}
    }
    G_RELAYS_IN_PROGRAM.splice( i, 1 ) ;
}   

function print_relay_in_program( relays_in_program ){
    var new_relay_div = create_div( { "id" : relays_in_program.get_relay_id() + "_relay" } ) ;
    var new_slid_div  = create_div( { "id" : relays_in_program.get_program_id() + relays_in_program.get_relay_id() + "_slider" }  ) ;
    var p             = create_h6( relays_in_program.get_relay_id() + "_p" ) ;
    var conn          = create_h6( relays_in_program.get_relay_id() + "_prog_conn" ) ;
    var remove_relay  = create_button_as_img( relays_in_program.get_relay_id() + "_btn", removerelay_from_program, relays_in_program.get_relay_id(), "img/clear.png" ) ;

    var relay = G_RELAYS.get_relay_by_id( relays_in_program.get_relay_id() ) ;
    var program = G_PROGRAMS.get_program_by_id( relays_in_program.get_program_id() ) ;

    p.innerHTML = relay.get_name() + ":  " + String( relays_in_program.get_start() ).toHHMM() + " " + String( relays_in_program.get_stop() ).toHHMM()  ;

    new_relay_div.appendChild( p ) ;                
    new_relay_div.appendChild( conn ) ;                
    new_relay_div.appendChild( new_slid_div ) ;     
    new_relay_div.appendChild( remove_relay ) ;     

    document.getElementById( "actual_program" ).appendChild( new_relay_div ) ;

    G_RELAYS.print_connections( relay.get_id(), relay.get_id() + "_prog_conn" ) ;
        
    $( "#" + relays_in_program.get_program_id() + relays_in_program.get_relay_id() + "_slider" ).slider({
      range: true ,
      min: 0      ,
      max: 86400  ,
      step: 300   ,
      values: [ relays_in_program.get_start(), relays_in_program.get_stop() ],
      slide: function( event, ui ) {
    	  p.innerHTML = relay.get_name() + ":  " + String(  ui.values[ 0 ] ).toHHMM() + " " + String( ui.values[ 1 ] ).toHHMM()  ;
      } ,
      stop: function( event, ui ) {
        relays_in_program.set_start( ui.values[ 0 ] ) ; 
        relays_in_program.set_stop( ui.values[ 1 ] ) ; 
        var relay = G_RELAYS.get_relay_by_id( relays_in_program.get_relay_id() ) ;

        p.innerHTML = relay.get_name() + ":  " + String(  relays_in_program.get_start() ).toHHMM() + " " + String( relays_in_program.get_stop() ).toHHMM()  ;
        var selected_program  = document.getElementById("program_list").value ;
        //G_RELAYS_IN_PROGRAM[ i ].get_program_id() == selected_prog
	    for( var cnt = 0; cnt < G_RELAYS_IN_PROGRAM.length; cnt++ ){
            if( relays_in_program.get_relay_id() == G_RELAYS_IN_PROGRAM[ cnt ].get_relay_id() ){
                continue ;
            } else if( G_RELAYS_IN_PROGRAM[ cnt ].get_program_id() == selected_program ){
            	var start = G_RELAYS_IN_PROGRAM[ cnt ].get_start() ;
            	var stop  = G_RELAYS_IN_PROGRAM[ cnt ].get_stop() ;
            	var conn_relay = G_RELAYS.get_relay_by_id( G_RELAYS_IN_PROGRAM[ cnt ].get_relay_id() ) ;
            	if ( (  ui.values[ 0 ] >= start && ui.values[ 0 ] <= stop ) && 
            			( ui.values[ 1 ] >= start && ui.values[ 1 ] <= stop ) ){
            		p.innerHTML += conn_relay.get_name() + "  ";
            	} else if(0){
            		
            	}
            }
        }
      }
    });
}


function new_slider(){
    var new_relay_a = create_button_as_img( "add", new_relay, "add", "img/add.png" ) ;
    var new_prog_a  = create_button_as_img( "add", new_program, "add", "img/add.png" ) ;

    document.getElementById( "new_relay" ).appendChild( new_relay_a ) ;
    document.getElementById( "new_program" ).appendChild( new_prog_a ) ;
}

function new_relay(){
    var name = document.getElementById( "new_relay_name" ).value ;
    G_RELAYS.add_new_relay( { "name" : name } ) ;
    print_available_relays() ;
}

function new_program(){
    var name = document.getElementById( "new_program_name" ).value ;
    
    G_PROGRAMS.add_new_program( { "name" : name } ) ;
    
    print_available_programs() ;
}


function add_relay_to_program(){
    var selected_relay = $("#relay_list").children(":selected").attr("id");
    var selected_prog  = $("#program_list").children(":selected").attr("id");
    
    if ( selected_relay == null || selected_prog == null ){
        return ;
    }
    
    for( var i = 0; i < G_RELAYS_IN_PROGRAM.length; i++ ){
    	if( G_RELAYS_IN_PROGRAM[ i ].get_relay_id() == selected_relay &&
    	    G_RELAYS_IN_PROGRAM[ i ].get_program_id() == selected_prog	){
    		return ;
    	}
    }
    G_RELAYS_IN_PROGRAM[ i ] = new Relay_in_program( {
    	'relay_id' : selected_relay,
    	'program_id' : selected_prog,
    	'start' : DEF_START,
    	'stop' : DEF_STOP,
    }) ;
    
    var ret_val = new Object( { 'add_relay_to_program' : 1 } ) ;
    
    push_cmd("add_relay_to_program", JSON.stringify( {
    	'relay_id' : selected_relay,
    	'program_id' : selected_prog,
    	'start' : DEF_START,
    	'stop' : DEF_STOP,
    } ) ) ;
    ret_val = processor( send_cmd(), ret_val) ;

    if ( ret_val[ 'add_relay_to_program' ] ){
    	print_relay_in_program( G_RELAYS_IN_PROGRAM[ i ] ) ;
    }
}

function print_available_relays(){
    if( document.getElementById("relay_list") ){
        document.getElementById("relay_list").innerHTML = "" ;
    }

    var relays     = G_RELAYS.get_relay_list_to_select_list() ;
    var relay_list = create_select_list_fea( "relays", "relay_list", relays, add_relay_to_program ) ; //  create_select_list_fea(name, id, list, func) {
    document.getElementById( "lists" ).appendChild( relay_list ) ;

}

function open_program(){
    $( "#toolbar" ).show() ;
    $( "#repetition_time" ).show() ;
    $( "#program_name" ).show() ;
    $( "#save_prog_data" ).show() ;
    
    document.getElementById( "actual_program" ).innerHTML = "" ;
    var selected_prog  = $("#program_list").children(":selected").attr("id");
    var program = G_PROGRAMS.get_program_by_id( selected_prog ) ;
    $( "#repetition_time" ).val( program.get_repetition_time() ) ;
    $( "#program_name" ).val( program.get_name() ) ;
    
    create_button_as_img( "save_prog_data" +  program.get_id(), save_program, "save", "img/save.png" ) ;
    var options = {
            label: ( program.get_status() == execution.START ? "pause" : "play"),
            icons: {
              primary: ( program.get_status() == execution.START ? "ui-icon-pause" : "ui-icon-play" ) ,
            }
          } ;
    
    for( var cnt = 0; cnt < G_RELAYS_IN_PROGRAM.length; cnt++ ){
    	if( G_RELAYS_IN_PROGRAM[ cnt ].get_program_id() == program.get_id() ){
    		print_relay_in_program( G_RELAYS_IN_PROGRAM[ cnt ] ) ;
    	}
    }
    $( "#play" ).button( "option", options );
}

$(function() {
    $( "#play" ).button({
      text: false,
      icons: {
        primary: "ui-icon-play"
      }
    })
    .click(function() {
      var options;
      if ( $( this ).text() === "play" ) {
        options = {
          label: "pause",
          command : execution.START,
          icons: {
            primary: "ui-icon-pause"
          }
        };
      } else {
        options = {
          label: "play",
          command : execution.PAUSE,
          icons: {
            primary: "ui-icon-play"
          }
        };
      }
      $( this ).button( "option", options );
        var prog_id = document.getElementById("program_list").value ;
        var program = G_PROGRAMS.get_program_by_id( prog_id ) ;
        program.set_status( options.command );

    });
    $( "#stop" ).button({
      text: false,
      icons: {
        primary: "ui-icon-stop"
      }
    })
    .click(function() {
       var prog_id = document.getElementById("program_list").value ;
       var program = G_PROGRAMS.get_program_by_id( prog_id ) ;
       program.set_status( execution.STOP ) ;
      $( "#play" ).button( "option", {
        label: "play",
        icons: {
          primary: "ui-icon-play"
        }
      });
    });
  
    
  });

  
  
  