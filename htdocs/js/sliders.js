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
    	var _this = this;
        this.save_data_to_db( {
        	'stop'             : stop,
        	'program_id'       : this.get_program_id(),
        	'relay_id'         : this.get_relay_id(),
        	'program_relay_id' : this.get_program_relay_id()
        }, function (){
        	_this.stop = stop ;
        }, function() {
            alert ( "start is not saved" ) ;
        } ) ;
    };
    this.set_start = function( start ){
    	var _this = this;
        this.save_data_to_db( {
        	'start'             : start,
        	'program_id'       : this.get_program_id(),
        	'relay_id'         : this.get_relay_id(),
        	'program_relay_id' : this.get_program_relay_id()
        }, function (){
        	_this.start = start ;
        }, function() {
            alert ( "start is not saved" ) ;
        } ) ;
    };
    this.remove_relay_in_program = function(){
        push_cmd("remove_relay_in_program", JSON.stringify( {
        	'program_id' : this.get_program_id(),
        	'relay_id' : this.get_relay_id()
        } ) ) ;
        var ret_val = processor( send_cmd()) ;
    }
    this.save_data_to_db = function( save_data, success_callback, error_callback ){
    	msg();
        push_cmd("update_relay_prog_data_to_db", JSON.stringify( save_data ), success_callback, error_callback ) ;
        processor( send_cmd( ASYNC ) ) ;
    }
};

function get_relays_in_programs(){
    push_cmd( "get_relays_in_programs", JSON.stringify( new Object( { 'get' : 1 } ) ) ) ;
    var ret_val = processor( send_cmd() ) ;
    if( ret_val[ 'get_relays_in_programs' ] ){
    	G_RELAYS_IN_PROGRAM = $.map( ret_val[ 'get_relays_in_programs' ], function(params, index) {
    		return new Relay_in_program( params );
    	});
    }
}

function removerelay_from_program( relay, program ){
    remove_by_id( relay.get_id() + "_relay" ) ;

    $.grep( G_RELAYS_IN_PROGRAM, function(item, i) {
    	return item.get_relay_id() == relay.get_id() && item.get_program_id() == program.get_id()
    } ).forEach( function( item ) {
    	item.remove_relay_in_program();
    } );
    get_relays_in_programs();
    open_program();
}

function print_relay_in_program( relays_in_program ){
    var new_relay_div = create_div( { "id" : relays_in_program.get_relay_id() + "_relay", class : 'bordered' } ) ;
    var new_slid_div  = create_div( { "id" : relays_in_program.get_program_id() + relays_in_program.get_relay_id() + "_slider" }  ) ;
    var p             = create_h6( relays_in_program.get_relay_id() + "_p" ) ;
    var conn          = create_h6( relays_in_program.get_relay_id() + "_prog_conn" ) ;
    var remove_relay  = create_button_as_img( relays_in_program.get_relay_id() + "_btn", function(){
    	removerelay_from_program( $( this ).data('data').relay, $( this ).data( 'data' ).program);
    }, relays_in_program.get_relay_id(), "img/clear.png" ) ;
    var relay = G_RELAYS.get_relay_by_id( relays_in_program.get_relay_id() ) ;
    var program = G_PROGRAMS.get_program_by_id( relays_in_program.get_program_id() ) ;

    var relay_struct = {
		relays_in_program : relays_in_program,
		program           : program,
		relay             : relay
	};
    $( new_relay_div ).data( 'data', relay_struct );
    $( new_slid_div ).data( 'data', relay_struct );
    $( p ).data( 'data', relay_struct );
    $( conn ).data( 'data', relay_struct );
    $( remove_relay ).data( 'data', relay_struct );

    $( p ).html( relay.get_name() + ":  " + String( relays_in_program.get_start() ).toHHMM() + " " + String( relays_in_program.get_stop() ).toHHMM() ) ;

    $( new_relay_div ).append( p ) ;
    $( new_relay_div ).append( conn ) ;
    $( new_relay_div ).append( new_slid_div ) ;
    $( new_relay_div ).append( remove_relay ) ;
    var h3 = create_h3();
    $(h3).html(  relay.get_name() );
    $( "#actual_program" ).append( h3 ) ;
    $( "#actual_program" ).append( new_relay_div ) ;
    $( "#actual_program" ).accordion("refresh");

    G_RELAYS.print_connections( relay, relay.get_id() + "_prog_conn" ) ;

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
      	msg();
        relays_in_program.set_start( ui.values[ 0 ] ) ;
        relays_in_program.set_stop( ui.values[ 1 ] ) ;
        var relay = $( this ).data('data').relay ;
        var program = $( this ).data('data').program ;
        p.innerHTML = relay.get_name() + ":  " + String(  relays_in_program.get_start() ).toHHMM() + " - " + String( relays_in_program.get_stop() ).toHHMM()  ;
        $( p ).parent().prev().html( p.innerHTML ) ;
        var selected_program  = document.getElementById("program_list").value ;
        //G_RELAYS_IN_PROGRAM[ i ].get_program_id() == selected_prog
	    for( var cnt = 0; cnt < G_RELAYS_IN_PROGRAM.length; cnt++ ){
            if( relay.get_id() == G_RELAYS_IN_PROGRAM[ cnt ].get_relay_id() ){
                continue ;
            } else if( G_RELAYS_IN_PROGRAM[ cnt ].get_program_id() == program.get_id() ){
            	var start = G_RELAYS_IN_PROGRAM[ cnt ].get_start() ;
            	var stop  = G_RELAYS_IN_PROGRAM[ cnt ].get_stop() ;
            	var conn_relay = G_RELAYS.get_relay_by_id( G_RELAYS_IN_PROGRAM[ cnt ].get_relay_id() ) ;
            	if ( (  ui.values[ 0 ] >= start && ui.values[ 0 ] <= stop ) ||
            			( ui.values[ 1 ] >= start && ui.values[ 1 ] <= stop ) ){
            		p.innerHTML += conn_relay.get_name() + "  ";
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
    var selected_relay = $("#relay_list").children(":selected").data('data');
    var selected_prog  = $("#program_list").children(":selected").data('data');

    if ( selected_relay == null || selected_prog == null ){
        return ;
    }

    push_cmd("add_relay_to_program", JSON.stringify( {
    	'relay_id' : selected_relay.get_id(),
    	'program_id' : selected_prog.get_id(),
    	'start' : DEF_START,
    	'stop' : DEF_STOP,
    } ), function(){
        get_relays_in_programs();
    	print_relay_in_program( G_RELAYS_IN_PROGRAM.find( function( relay_in_program ) {
    		return relay_in_program.get_program_id() == selected_prog.get_id() &&
    			   relay_in_program.get_relay_id()   == selected_relay.get_id()
    	} ) )
    } ) ;
    processor( send_cmd() ) ;
}

function print_available_relays(){
    if( $("#relay_list") ){
        $("#relay_list").html( "" ) ;
    }

    var relay_list = create_select_list_fea( "relays", "relay_list", G_RELAYS.get_relay_list_to_select_list(), add_relay_to_program ) ; //  create_select_list_fea(name, id, list, func) {
    $( "#lists" ).append( relay_list ) ;

}

function open_program( option ){
	$.each(['program_data', 'toolbar', 'repetition_time', 'program_name', 'save_prog_data'], function(i,n){
		$( '#' + n ).show();
	});

    $( "#actual_program" ).html( "" ) ;
    $( "#actual_program" ).accordion({ collapsible: true });
    var program = $( '#program_list' ).find( ':selected' ).data( 'data' ) ;
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
	  var program = $("#program_list :selected").data('data') ;
	  program.set_status( options.command );

    });
    $( "#stop" ).button({
      text: false,
      icons: {
        primary: "ui-icon-stop"
      }
    })
    .click(function() {
  	  var program = $("#program_list :selected").data('data') ;
	  program.set_status( options.command );
      program.set_status( execution.STOP ) ;
      $( "#play" ).button( "option", {
        label: "play",
        icons: {
          primary: "ui-icon-play"
        }
      });
    });
  });

