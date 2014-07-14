


  c=$1
  c_rangetype=$2
  c_struct_pref=$3
  c_covtype='RectifiedGridCoverage'
  PS_USER='rasdaman'
  PS_DB='petascopedb'

  c_crs='%SECORE_URL%/crs/OGC/0/Index2D'
  min_x_geo_coord="0"
  max_y_geo_coord="0"
  x_res='1'
  y_res='-1'
  

  RASQL="/home/rasdaman/install/bin/rasql --user rasadmin --passwd rasadmin"
  PSQL="psql -U $PS_USER -d $PS_DB"

  # general coverage information (name, type, ...)
  $PSQL -c "INSERT INTO ps_coverage (name, gml_type_id, native_format_id) \
            VALUES ('$c', (SELECT id FROM ps_gml_subtype WHERE subtype='$c_covtype'), \
            (SELECT id FROM ps_mime_type WHERE mime_type='application/x-octet-stream'));" > /dev/null || exit $RC_ERROR

  # get the coverage id
  c_id=$($PSQL -c  "SELECT id FROM ps_coverage WHERE name = '$c' " | head -3 | tail -1) > /dev/null || exit $RC_ERROR

  # get the collection OID (note: take the first OID)
  c_oid=$($RASQL -q "select oid(m) from $c as m" --out string | grep ' 1:' | awk -F ':' '{print $2}' | tr -d ' \n') > /dev/null || exit $RC_ERROR

  # range set: link the coverage to the rasdaman collection
  $PSQL -c "INSERT INTO ps_rasdaman_collection (name, oid) VALUES ('$c', $c_oid);" > /dev/null
  $PSQL -c "INSERT INTO ps_range_set (coverage_id, storage_id) VALUES (\
              (SELECT id FROM ps_coverage WHERE name='$c'), \
              (SELECT id FROM ps_rasdaman_collection WHERE name='$c'));" > /dev/null || exit $RC_ERROR

  ##############################################################################################################
  # describe the datatype of the coverage cell values (range type)
  # note: assign dimensionless quantity

  ii=0
  for struct_post in _mod_m1_f1 _pha_m1_f1 _mod_00_f1 _pha_00_f1 _mod_p1_f1 _pha_p1_f1 _mod_m1_f2 _pha_m1_f2 _mod_00_f _pha_00_f2 _mod_p1_f2 _pha_p1_f2
  do
    struct_name=$c_struct_pref$struct_post
    $PSQL -c "INSERT INTO ps_range_type_component (coverage_id, name, component_order, data_type_id, field_id) VALUES (\
              $c_id, '$struct_name', $ii, \
              (SELECT id FROM ps_range_data_type WHERE name='$c_rangetype'), \
              (SELECT id FROM ps_quantity WHERE label='$c_rangetype' AND description='primitive' LIMIT 1));" > /dev/null || exit $RC_ERROR
  ii=$[ii+1]
  done
  ##############################################################################################################
  # describe the geo (`index` in this case..) domain
  # $PSQL -c "INSERT INTO ps_crs (uri) SELECT '$c_crs' WHERE NOT EXISTS (SELECT 1 FROM ps_crs WHERE uri='$c_crs');" > /dev/null
  $PSQL -c "INSERT INTO ps_domain_set (coverage_id, native_crs_ids) \
            VALUES ($c_id, ARRAY[(SELECT id FROM ps_crs WHERE uri='$c_crs')]);" > /dev/null || exit $RC_ERROR
  $PSQL -c "INSERT INTO ps_gridded_domain_set (coverage_id, grid_origin) \
            VALUES ($c_id, '{$max_y_geo_coord, $min_x_geo_coord}');" > /dev/null || exit $RC_ERROR
  # grid axes:
  $PSQL -c "INSERT INTO ps_grid_axis (gridded_coverage_id, rasdaman_order) VALUES ($c_id, 0);" > /dev/null || exit $RC_ERROR
  $PSQL -c "INSERT INTO ps_grid_axis (gridded_coverage_id, rasdaman_order) VALUES ($c_id, 1);" > /dev/null || exit $RC_ERROR

  # offset vectors
  $PSQL -c "INSERT INTO ps_rectilinear_axis (grid_axis_id, offset_vector) VALUES (\
              (SELECT id FROM ps_grid_axis WHERE gridded_coverage_id=$c_id AND rasdaman_order=0), \
              '{0, $x_res}');" > /dev/null || exit $RC_ERROR
  $PSQL -c "INSERT INTO ps_rectilinear_axis (grid_axis_id, offset_vector) VALUES (\
              (SELECT id FROM ps_grid_axis WHERE gridded_coverage_id=$c_id AND rasdaman_order=1), \
              '{$y_res, 0}');" > /dev/null || exit $RC_ERROR
