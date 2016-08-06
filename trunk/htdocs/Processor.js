var FUNCTIONS = new Object() ;


function push_cmd(key, value) {
	PROC_ARRAY[key] = value;

}

function send_cmd( async_ ) {
	console.log( PROC_ARRAY );
	console.log( '/cgi-bin/' + CGI_PATH + '/SaveForm1.pl' );

	result = AJAX_req({
			'url' : '/cgi-bin/' + CGI_PATH + '/SaveForm1.pl',
			'data' : PROC_ARRAY
		},
		async_
	);
	PROC_ARRAY = new Object();
	return result;
}

function processor(data_to_process, ret_val) {
    console.log( data_to_process ) ;
    
    for ( var cmd in data_to_process) {
		
        if( ret_val != null && ret_val[ cmd ] != null ){
            ret_val[ cmd ] = data_to_process[ cmd ] ;
        }
    }
    if(  data_to_process != null && data_to_process[ 'errors' ] && data_to_process[ 'time' ] )
    {
	   	error_messages_and_server_comm_times( {
			'errors'  : data_to_process[ 'errors' ], 
			'times'   : data_to_process[ 'time' ]  , 
		} ); 
    }
    if ( data_to_process != null && data_to_process != null && data_to_process[ 'time' ] ){
    	print_measure( data_to_process[ 'time' ] ) ;
    
    }
		
    return ret_val ;
}


