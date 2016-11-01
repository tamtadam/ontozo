function AJAX_req( data, async_ ){
	async_ == null ? async_ = false : 0 ;
    var return_dataa = null ;
    var key;
    for (i in data['data'])
    {
        if ( i != "session_data" ){
            key = i;
        }
    }
    $.ajax({
            url: data['url'] ,
            type: 'POST',
            contentType: 'application/x-www-form-urlencoded; charset=utf-8',
            data: data['data'],
            dataType: 'json',
            async: async_ ,
            success: function( dataa ){
                            return_dataa = dataa ;
                            if ( async_ )
                            {
                            	processor( dataa ) ;
                            }
                        },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
            	//alert("XMLHttpRequest="+XMLHttpRequest.responseText+"\ntextStatus="+textStatus+"\nerrorThrown="+errorThrown);
        }
    });
    return return_dataa ;

}