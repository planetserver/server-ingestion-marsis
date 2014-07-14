function MARSIS_postgis_ingest_echo_meta(meta,MARSIS_META_TABLE)

%	length(meta)==35 || error ("Incosistent metadata array length");

	if nargin<6
		MARSIS_META_COLLECTION = 'MARSIS_meta';
	end


	query_fields( 1).name = 'orbit_id';
	query_fields( 2).name = 'echo_id';
	query_fields( 3).name = 'sub_sc_lon';
	query_fields( 4).name = 'sub_sc_lat';
	query_fields( 5).name = 'coordinate';
	query_fields( 6).name = 'f1';
	query_fields( 7).name = 'f2';
	query_fields( 8).name = 'slope';
	query_fields( 9).name = 'scet_frame_w';
	query_fields(10).name = 'scet_frame_f';
	query_fields(11).name = 'h_scet';
	query_fields(12).name = 'vt_scet';
	query_fields(13).name = 'vr_scet';
	query_fields(14).name = 'delta_s_scet';
	query_fields(15).name = 'na_scet_1';
	query_fields(16).name = 'na_scet_2';
	query_fields(17).name = 'geom_ephem_t';
	query_fields(18).name = 'geom_epoch_utc';
	query_fields(19).name = 'solar_lon';
	query_fields(20).name = 'mars_sun_dist';
	query_fields(21).name = 'target_name';
	query_fields(22).name = 'target_sc_pos_x';
	query_fields(23).name = 'target_sc_pos_y';
	query_fields(24).name = 'target_sc_pos_z';
	query_fields(25).name = 'sc_alt';
	query_fields(26).name = 'target_sc_vel_x';
	query_fields(27).name = 'target_sc_vel_y';
	query_fields(28).name = 'target_sc_vel_z';
	query_fields(29).name = 'target_sc_rad_v';
	query_fields(30).name = 'target_sc_tan_v';
	query_fields(31).name = 'loc_solar_t';
	query_fields(32).name = 'solar_zen';
	query_fields(33).name = 'di_uni_x';
	query_fields(34).name = 'di_uni_y';
	query_fields(35).name = 'di_uni_z';
	query_fields(36).name = 'mono_uni_x';
	query_fields(37).name = 'mono_uni_y';
	query_fields(38).name = 'mono_uni_z';

	for ii = [1:4, 6:38]
		query_fields(ii).value = eval(["meta." query_fields(ii).name]);
	end
	
	
	if query_fields(3).value > 180
		lon = query_fields(3).value - 360;
	else
		lon = query_fields(3).value;
	end

	query_fields(5).value = ["ST_GeomFromText('POINT(" sprintf("%22.20f", lon) " " sprintf("%22.20f", query_fields(4).value)  ")', 4326)"]	;

%%%BUILDING QUERY%%%%
	query_string = ["\"INSERT INTO " MARSIS_META_TABLE " ("];
	for ii = 1:37
		query_string = [query_string query_fields(ii).name ","];
	end
	query_string = [query_string query_fields(38).name ") VALUES ("];
	for ii = 1:37
		if isnumeric(query_fields(ii).value) 
%			query_string = [query_string num2str(query_fields(ii).value) ","];
			query_string = [query_string sprintf("%20.18f", query_fields(ii).value) ","];
		else
			if ii == 5
				query_string = [query_string query_fields(ii).value ","];
			else
				query_string = [query_string "'" query_fields(ii).value "',"];
			end
		end
	end
	query_string = [query_string sprintf("%22.20f", query_fields(38).value) ")\""];

	system (["psql -d marsisdb -c " query_string]);

	

