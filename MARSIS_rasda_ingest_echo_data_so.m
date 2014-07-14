function MARSIS_rasda_ingest_echo_data_so(data,orbit_id,echo_id,MARSIS_DATA_COLLECTION)

%	if nargin<6
%		MARSIS_DATA_COLLECTION = 'MARSIS_data';
%	end
%	if (isscalar(data))
	%	data =
%	end
%	sd = size(data);
%	(sd(1)==512) || error ("Incosistent data array length");







	data_string=[];
	for ii=0:510
		data_string=[data_string sprintf("{%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff};",data(ii+1,:))];
	end	
%	data_string=[data_string sprintf("{%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff}",[data(ii+2,:) sim(ii+2,:)])];
	data_string=[data_string sprintf("{%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff,%ff}",data(ii+2,:))];



%	query_string = sprintf("rasql -q 'insert into %s values marray %s in [%d:%d,%d:%d] values <%s> ' --user rasadmin --passwd rasadmin", MARSIS_DATA_COLLECTION, MARSIS_DATA_TYPE, echo_id-1, echo_id-1, 0, 511, data_string);


	query_string = sprintf("rasql -q 'update %s as m set m[%d:%d,%d:%d] assign <[%d:%d,%d:%d] %s >' --user rasadmin --passwd rasadmin", MARSIS_DATA_COLLECTION, echo_id-1, echo_id-1, 0, 511, echo_id-1, echo_id-1, 0, 511, data_string);


	[status, output] = system (query_string)

%	fid=fopen('query.txt','w');
%	fprintf(fid, "%s", query_string);
%	fclose(fid);

