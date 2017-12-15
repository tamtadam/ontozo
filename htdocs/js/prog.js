var programs;

function get_program_list(){
    push_cmd( "get_program_list", JSON.stringify( new Object( { 'get' : 1 } ) )) ;
    ret_val = processor( send_cmd() ) ;
    programs = ret_val[ 'get_program_list' ] ;
}

function get_all_status() {
    push_cmd( "get_all_status", JSON.stringify( new Object( { 'get' : 1 } ) ), function(data) {
    	var status_container = $( '#relay_and_rpi_status' );
    	status_container.html( "" );
    	for ( var name in data ) {
    		var relay = create_div();
			var title = create_h3();
			$( title ).html( name );
			var content = create_h5();
			var str = "";
			
    		for ( pos in data[ name ] ) {
    			str += pos + ": " + data[ name ][ pos ] + '</br>';
    		}
			$( content ).html( str );
			status_container.append( title );
			status_container.append( content );
    	}
    } ) ;
    ret_val = processor( send_cmd( true ) ) ;
}

function Programs( program_data ){
	var _this = this;
    this.programs = $.map( program_data, function( program, index ) {
    	return new Program( program );
    } ) ;
}

Programs.prototype.get_program_by_id = function ( prog_id ){
	return this.programs.find( function( item, index) {
		return item.get_id() == prog_id;
	} );
}

Programs.prototype.add_new_program = function( data ){
    push_cmd( "add_new_program", JSON.stringify( data ) ) ;
    var ret_val = processor( send_cmd() ) ;
    data.program_id = ret_val[ 'add_new_program' ] ;

    if( data.program_id != null ){
	    this.programs.push( new Program( data ) ) ;
    } else {
        alert( "Program is not added" ) ;
    }
}

Programs.prototype.get_program_list_to_select = function(){
    var _this = this;
    return $.map(_this.programs, function(program, index) {
    	return ( { 'title' : program.get_name(), 'id' : program.get_id(), 'data' : program } )
    });
}

function print_available_programs(){
    if( $("#program_list").length ){
    	$("#program_list").html('') ;
    }
    var program_list = create_select_list_fea( "program_list", "program_list", G_PROGRAMS.get_program_list_to_select() , open_program ) ; //  create_select_list_fea(name, id, list, func) {
    $( "#lists" ).append( program_list ) ;
    $("#program_list").val( -1 );
}


function Program( prog_data ){
    prog_data && prog_data.start           ? this.start = prog_data.start         : this.start  =  DEF_START ;
    prog_data && prog_data.program_id      ? this.id    = prog_data.program_id    : this.id     = -1 ;
    prog_data && prog_data.name            ? this.name  = prog_data.name          : this.name   = 'NO name' ;
    prog_data && prog_data.stop            ? this.stop  = prog_data.stop          : this.stop   = DEF_STOP ;
    prog_data && prog_data.run_status_id   ? this.status= prog_data.run_status_id : this.status = execution.START ;
    prog_data && prog_data.repetition_time ? this.repetition_time = prog_data.repetition_time : this.repetition_time = 0 ;

    this.get_name = function(){
        return this.name ;
    };
    this.get_id = function(){
        return this.id ;
    };
    this.get_status = function(){
        return this.status ;
    };
    this.get_repetition_time = function(){
        return this.repetition_time ;
    };
    this.set_name = function( name ){
        if ( this.save_program_data_to_db( { 'name' : name } ) ){
            this.name = name ;
        } else {
            alert ( "name is not saved" ) ;
        }
    };
    this.set_id = function( id ){
        if ( this.save_program_data_to_db( { 'id' : id } ) ){
            this.id = id ;
        } else {
            alert ( "id is not saved" ) ;
        }
    };
    this.set_status = function( status ){
        console.log( status ) ;
        if ( this.save_program_data_to_db( { 'status' : status } ) ){
            this.status = status ;
        } else {
            alert ( "status is not saved" ) ;
        }
    };
    this.set_repetition_time = function( repetition_time ){
        if ( this.save_program_data_to_db( { 'repetition_time' : repetition_time } ) ){
            this.repetition_time = repetition_time ;
        } else {
            alert ( "repetition_time is not saved" ) ;
        }
    };

    this.save_program_data_to_db = function( save_data ){
    	msg();
    	save_data.id = this.get_id() ;
        console.log( save_data );

        push_cmd("save_program_data_to_db", JSON.stringify( save_data ) ) ;
        var ret_val = processor( send_cmd(), ret_val) ;

        if ( ret_val[ 'save_program_data_to_db' ] ){
            return true ;
        } else {
            return false ;
        }
    }
}

function save_program() {
    var program_id = $("#program_list").children(":selected").attr("id");

    var program = G_PROGRAMS.get_program_by_id( program_id ) ;

    var value = $("#repetition_time" ).val() ;
    if ( value && program.get_repetition_time() != value ){
        program.set_repetition_time( value ) ;
    }

    value = $("#program_name" ).val() ;
    if ( value && program.get_name() != value ){
        program.set_name( value ) ;
    }
}

function init_page() {
    get_connections();
    get_relay_list() ;
    get_program_list();
    get_relays_in_programs() ;

    G_RELAYS = new Relays( RELAYS, CONNECTIONS );
    G_PROGRAMS = new Programs( programs );

    console.log( G_RELAYS ) ;

    $( document ).ready(function(){
    		print_available_programs();
    		print_available_relays();
    		new_slider();
    		create_on_off_for_relay();
    } ) ;
}

function update_method(){
	setInterval(function(){
	    get_connections();
	    get_relay_list() ;
	    get_program_list();
	    get_relays_in_programs() ;
	    G_RELAYS = new Relays( RELAYS, CONNECTIONS );
	    G_PROGRAMS = new Programs( programs );
	    $( document ).ready( create_on_off_for_relay() ) ;
	}, 60000);

	setInterval(function(){
	    get_all_status();
	}, 120000);

}
