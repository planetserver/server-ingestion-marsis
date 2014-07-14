function MARSIS_postgis_ingest_orbit(orbit_id, ingest_data, ingest_sim, ingest_meta)

tic

if (nargin<4) error("NOT enough input arguments"); end

RdrDir    = '../../MARSIS_data_l2';
EdrSimDir = '../../MARSIS_sim';
MARSIS_DATA_COLLECTION = 'MARSIS_dataP';
MARSIS_META_COLLECTION = 'MARSIS_echo_meta';

%%%% DATA and METADATA files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (orbit_id<9999)
	EdrSimFile = ['E_0',num2str(orbit_id),'_SS3_TRK_CMP_M_SIM.DAT'];
	RdrFile    = ['R_0',num2str(orbit_id),'_SS3_TRK_CMP_M.DAT'];
else
	EdrSimFile = ['E_', num2str(orbit_id),'_SS3_TRK_CMP_M_SIM.DAT'];
	RdrFile    = ['R_', num2str(orbit_id),'_SS3_TRK_CMP_M.DAT'];
end
if (EdrSimDir==0) EdrSimDir =  DefEdrSimDir; end
if (RdrDir==0)    RdrDir    =  DefRdrDir; end
EdrSimFile = fullfile(EdrSimDir,EdrSimFile);
RdrFile    = fullfile(RdrDir,RdrFile);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ingest_data
    %%% Reading DATA from RDR file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ECHO_MODULUS_MINUS1_F1_DIP = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_MINUS1_F1_DIP' );
    ECHO_PHASE_MINUS1_F1_DIP   = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_MINUS1_F1_DIP' );
    ECHO_MODULUS_ZERO_F1_DIP   = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_ZERO_F1_DIP' );
    ECHO_PHASE_ZERO_F1_DIP     = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_ZERO_F1_DIP' );
    ECHO_MODULUS_PLUS1_F1_DIP  = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_PLUS1_F1_DIP' );
    ECHO_PHASE_PLUS1_F1_DIP    = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_PLUS1_F1_DIP' );
    ECHO_MODULUS_MINUS1_F2_DIP = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_MINUS1_F2_DIP' );
    ECHO_PHASE_MINUS1_F2_DIP   = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_MINUS1_F2_DIP' );
    ECHO_MODULUS_ZERO_F2_DIP   = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_ZERO_F2_DIP' );
    ECHO_PHASE_ZERO_F2_DIP     = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_ZERO_F2_DIP' );
    ECHO_MODULUS_PLUS1_F2_DIP  = read_MARSIS_RDR( RdrFile, 'ECHO_MODULUS_PLUS1_F2_DIP' );
    ECHO_PHASE_PLUS1_F2_DIP    = read_MARSIS_RDR( RdrFile, 'ECHO_PHASE_PLUS1_F2_DIP' );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    data = [ECHO_MODULUS_MINUS1_F1_DIP ...
	    ECHO_PHASE_MINUS1_F1_DIP ...
	    ECHO_MODULUS_ZERO_F1_DIP ...
	    ECHO_PHASE_ZERO_F1_DIP ...
	    ECHO_MODULUS_PLUS1_F1_DIP ...
	    ECHO_PHASE_PLUS1_F1_DIP ...
	    ECHO_MODULUS_MINUS1_F2_DIP ...
	    ECHO_PHASE_MINUS1_F2_DIP ...
	    ECHO_MODULUS_ZERO_F2_DIP ...
	    ECHO_PHASE_ZERO_F2_DIP ...
	    ECHO_MODULUS_PLUS1_F2_DIP ...
	    ECHO_PHASE_PLUS1_F2_DIP];
	    
	[N_samples, N_echoes] = size(ECHO_MODULUS_MINUS1_F1_DIP);

end
    %%% Reading SIMULATIONS from EDR ISM file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #EdrSimFile ="../../MARSIS_sim/E_01886_SS3_TRK_CMP_M_SIM.DAT"; # altrimenti non trova la sim. Per mettere i adti senza sim.
    
if ingest_sim
    [ ~, ~, ~, ~, scetfw, ~, ~, ~, ~, x0, y0, z0, alt0, ~, ~, ~, ~, ~, esm1f1, es00f1, esp1f1, esm1f2, es00f2, esp1f2 ] = readmarsisedrsim( EdrSimFile );
	[N_samples, N_echoes] = size(esm1f1);
    ################################################################
    B  =   1e6; % bandwidth
    fs = 1.4e6; % echo sampling frequency
    Ns =   512; % number of echo samples

    [ ~ , f ] = fftvars( fs, Ns );
    [ iband ] = find( abs( f ) <= B/2 );
    fband = f( iband );
    Nf = length( fband );
    frames = length( scetfw );
    % window = ones( size( f ) );
    window = zeros( size( f ) );
    % window( iband ) = ifftshift( hamming( Nf ) );
    window( iband ) = ifftshift( hanning( Nf ) );
    window = reshape( window, Ns, 1 ) * ones( 1, frames );

    esm1f1 = window .* esm1f1;
    es00f1 = window .* es00f1;
    esp1f1 = window .* esp1f1;
    esm1f2 = window .* esm1f2;
    es00f2 = window .* es00f2;
    esp1f2 = window .* esp1f2;

    r_s_max = 3417500; % reference distance of echoes from the center of Mars
    c       = 299792458; % Velocity of light in vacuo in m/s
    alt_max = 25e3; % reference altitude over the Martian ellipsoid

    positn = [ x0; y0; z0 ];
    r = sqrt( x0.^2 + y0.^2 + z0.^2 );
    % [ ~, alt0 ] = cspice_nearpt( positn, a, a, b );

    deltat = 2 * ( r_s_max - r + alt0 - alt_max ) / c;

    [ deltat, f ] = meshgrid( deltat, f );

    phase =  exp( 2 .* 1i .* pi .* deltat .* f );

    esm1f1 = phase .* esm1f1;
    es00f1 = phase .* es00f1;
    esp1f1 = phase .* esp1f1;
    esm1f2 = phase .* esm1f2;
    es00f2 = phase .* es00f2;
    esp1f2 = phase .* esp1f2;

    em1f1 = ifft( esm1f1 );
    e00f1 = ifft( es00f1 );
    ep1f1 = ifft( esp1f1 );
    em1f2 = ifft( esm1f2 );
    e00f2 = ifft( es00f2 );
    ep1f2 = ifft( esp1f2 );

    % mola = molaset( lon_0, lat_0, 'radius', 128 );

    wm1f1 = 20 * log10( abs( em1f1 ) );
    w00f1 = 20 * log10( abs( e00f1 ) );
    wp1f1 = 20 * log10( abs( ep1f1 ) );
    wm1f2 = 20 * log10( abs( em1f2 ) );
    w00f2 = 20 * log10( abs( e00f2 ) );
    wp1f2 = 20 * log10( abs( ep1f2 ) );

    bwimage = [ wm1f1,wm1f1, w00f1,w00f1, wp1f1,wp1f1, wm1f2,wm1f2, w00f2,w00f2, wp1f2,wp1f2 ];

    dynrange = 65;

    maxbwimage = max( max( bwimage ) );

    bwimage( bwimage < maxbwimage - dynrange ) = maxbwimage - dynrange;

    bwimage = (rescale2d( bwimage, 0, 300 ))+1;

    ################################################################
    #sim_cmp = [esm1f1, es00f1, esp1f1, esm1f2, es00f2, esp1f2];
    #sim_cmp = [wm1f1, w00f1, wp1f1, wm1f2, w00f2, wp1f2];
    #sim_r = real(sim_cmp);
    #sim_i = imag(sim_cmp);
    #sim   = [sim_r, sim_i];
    #size(bwimage)
    #size(data)
    #imwrite(double(data),'test.jpg');
    max(max(data))
    min(min(data))
    max(max(bwimage))
    min(min(bwimage))
    #return;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if ingest_meta
    %%% Reading METADATA from RDR file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    CENTRAL_FREQUENCY          = read_MARSIS_RDR( RdrFile, 'CENTRAL_FREQUENCY' );
    SLOPE                      = read_MARSIS_RDR( RdrFile, 'SLOPE' );
    SCET_FRAME_WHOLE           = read_MARSIS_RDR( RdrFile, 'SCET_FRAME_WHOLE' );
    SCET_FRAME_FRAC            = read_MARSIS_RDR( RdrFile, 'SCET_FRAME_FRAC' );
    H_SCET_PAR                 = read_MARSIS_RDR( RdrFile, 'H_SCET_PAR' );
    VT_SCET_PAR                = read_MARSIS_RDR( RdrFile, 'VT_SCET_PAR' );
    VR_SCET_PAR                = read_MARSIS_RDR( RdrFile, 'VR_SCET_PAR' );
    DELTA_S_SCET_PAR           = read_MARSIS_RDR( RdrFile, 'DELTA_S_SCET_PAR' );
    NA_SCET_PAR                = read_MARSIS_RDR( RdrFile, 'NA_SCET_PAR' );
    GEOMETRY_EPHEMERIS_TIME    = read_MARSIS_RDR( RdrFile, 'GEOMETRY_EPHEMERIS_TIME' );
    GEOMETRY_EPOCH             = read_MARSIS_RDR( RdrFile, 'GEOMETRY_EPOCH' );
    MARS_SOLAR_LONGITUDE       = read_MARSIS_RDR( RdrFile, 'MARS_SOLAR_LONGITUDE' );
    MARS_SUN_DISTANCE          = read_MARSIS_RDR( RdrFile, 'MARS_SUN_DISTANCE' );
    ORBIT_NUMBER               = read_MARSIS_RDR( RdrFile, 'ORBIT_NUMBER' );
    TARGET_NAME                = read_MARSIS_RDR( RdrFile, 'TARGET_NAME' );
    TARGET_SC_POSITION_VECTOR  = read_MARSIS_RDR( RdrFile, 'TARGET_SC_POSITION_VECTOR' );
    SPACECRAFT_ALTITUDE        = read_MARSIS_RDR( RdrFile, 'SPACECRAFT_ALTITUDE' );
    SUB_SC_LONGITUDE           = read_MARSIS_RDR( RdrFile, 'SUB_SC_LONGITUDE' );
    SUB_SC_LATITUDE            = read_MARSIS_RDR( RdrFile, 'SUB_SC_LATITUDE' );
    TARGET_SC_VELOCITY_VECTOR  = read_MARSIS_RDR( RdrFile, 'TARGET_SC_VELOCITY_VECTOR' );
    TARGET_SC_RADIAL_VELOCITY  = read_MARSIS_RDR( RdrFile, 'TARGET_SC_RADIAL_VELOCITY' );
    TARGET_SC_TANG_VELOCITY    = read_MARSIS_RDR( RdrFile, 'TARGET_SC_TANG_VELOCITY' );
    LOCAL_TRUE_SOLAR_TIME      = read_MARSIS_RDR( RdrFile, 'LOCAL_TRUE_SOLAR_TIME' );
    SOLAR_ZENITH_ANGLE         = read_MARSIS_RDR( RdrFile, 'SOLAR_ZENITH_ANGLE' );
    DIPOLE_UNIT_VECTOR         = read_MARSIS_RDR( RdrFile, 'DIPOLE_UNIT_VECTOR' );
    MONOPOLE_UNIT_VECTOR       = read_MARSIS_RDR( RdrFile, 'MONOPOLE_UNIT_VECTOR' );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end



%meta = [CENTRAL_FREQUENCY(1) ...
%	CENTRAL_FREQUENCY(2) ...
%	SLOPE ...
%	SCET_FRAME_WHOLE ...
%	SCET_FRAME_FRAC ...
%	H_SCET_PAR ...
%	VT_SCET_PAR ...
%	VR_SCET_PAR ...
%	DELTA_S_SCET_PAR ...
%	NA_SCET_PAR(1) ...
%	NA_SCET_PAR(2) ...
%	GEOMETRY_EPHEMERIS_TIME ...
%	MARS_SOLAR_LONGITUDE ...
%	MARS_SUN_DISTANCE ...
%	ORBIT_NUMBER ...
%	TARGET_NAME(1) ...
%	TARGET_SC_POSITION_VECTOR(1) ...
%	TARGET_SC_POSITION_VECTOR(2) ...
%	TARGET_SC_POSITION_VECTOR(3) ...
%	SPACECRAFT_ALTITUDE ...
%	SUB_SC_LONGITUDE ...
%	SUB_SC_LATITUDE ...
%	TARGET_SC_VELOCITY_VECTOR(1) ...
%	TARGET_SC_VELOCITY_VECTOR(2) ...
%	TARGET_SC_VELOCITY_VECTOR(3) ...
%	TARGET_SC_RADIAL_VELOCITY ...
%	TARGET_SC_TANG_VELOCITY ...
%	LOCAL_TRUE_SOLAR_TIME ...
%	SOLAR_ZENITH_ANGLE ...
%	DIPOLE_UNIT_VECTOR(1) ...
%	DIPOLE_UNIT_VECTOR(2) ...
%	DIPOLE_UNIT_VECTOR(3) ...
%	MONOPOLE_UNIT_VECTOR(1) ...
%	MONOPOLE_UNIT_VECTOR(2) ...
%	MONOPOLE_UNIT_VECTOR(3)];

if ingest_data
	MARSIS_DATA_COLLECTION = 'data';
	COLLECTION_TYPE_DATA = 'MARSIS_data_cubeSO';
	ARRAY_0 = '[0:0, 0:0, 0:0]';
	VALUE_0_DATA='{0f,0f,0f,0f,0f,0f,0f,0f,0f,0f,0f,0f}';

	create_collection_string = ["rasql -q 'create collection MARSIS_" MARSIS_DATA_COLLECTION "_" num2str(orbit_id) " " COLLECTION_TYPE_DATA "' --user rasadmin --passwd rasadmin"];
	system(create_collection_string);

	init_collection_string = ["rasql -q 'insert into MARSIS_" MARSIS_DATA_COLLECTION "_" num2str(orbit_id) " values marray " COLLECTION_TYPE_DATA " in [0:" num2str(N_echoes) ",0:" num2str(N_samples) "] values " VALUE_0_DATA "'  --user rasadmin --passwd rasadmin"];
	system(init_collection_string);
	

end

if ingest_sim
%%% SIMULATiONS
	MARSIS_CSCS_COLLECTION = 'cscs';
	COLLECTION_TYPE_CSCS = COLLECTION_TYPE_DATA; %'MARSIS_cscs_cubeSO';
	VALUE_0_CSCS=VALUE_0_DATA;%'{0d,0d,0d,0d,0d,0d,0d,0d,0d,0d,0d,0d}';

	create_collection_string = ["rasql -q 'create collection MARSIS_" MARSIS_CSCS_COLLECTION "_" num2str(orbit_id) " " COLLECTION_TYPE_CSCS "' --user rasadmin --passwd rasadmin"];
	system(create_collection_string);

	init_collection_string = ["rasql -q 'insert into MARSIS_" MARSIS_CSCS_COLLECTION "_" num2str(orbit_id) " values marray " COLLECTION_TYPE_CSCS " in [0:" num2str(N_echoes) ",0:" num2str(N_samples) "] values " VALUE_0_CSCS "'  --user rasadmin --passwd rasadmin"];
	system(init_collection_string);
	

end
#return;


for ii = 1:N_echoes
    if ingest_meta
	    printf("%d\n",ii);
	    fflush(stdout);
	    meta.orbit_id 		= ORBIT_NUMBER(ii);
	    meta.echo_id		= ii;
	    meta.sub_sc_lon		= SUB_SC_LONGITUDE(ii);
	    meta.sub_sc_lat		= SUB_SC_LATITUDE(ii);
	    meta.f1			= CENTRAL_FREQUENCY(1,ii);
	    meta.f2			= CENTRAL_FREQUENCY(2,ii);
	    meta.slope		= SLOPE(ii);
	    meta.scet_frame_w	= SCET_FRAME_WHOLE(ii);
	    meta.scet_frame_f	= SCET_FRAME_FRAC(ii);
	    meta.h_scet		= H_SCET_PAR(ii);
	    meta.vt_scet		= VT_SCET_PAR(ii);
	    meta.vr_scet		= VR_SCET_PAR(ii);
	    meta.delta_s_scet	= DELTA_S_SCET_PAR(ii);
	    meta.na_scet_1		= NA_SCET_PAR(1,ii);
	    meta.na_scet_2		= NA_SCET_PAR(2,ii);
	    meta.geom_ephem_t	= GEOMETRY_EPHEMERIS_TIME(ii);
	    meta.geom_epoch_utc	= GEOMETRY_EPOCH(:,ii)';
	    meta.solar_lon		= MARS_SOLAR_LONGITUDE(ii);
	    meta.mars_sun_dist	= MARS_SUN_DISTANCE(ii);
	    meta.target_name	= TARGET_NAME(:,ii)';
	    meta.target_sc_pos_x	= TARGET_SC_POSITION_VECTOR(1,ii);
	    meta.target_sc_pos_y	= TARGET_SC_POSITION_VECTOR(2,ii);
	    meta.target_sc_pos_z	= TARGET_SC_POSITION_VECTOR(3,ii);
	    meta.sc_alt		= SPACECRAFT_ALTITUDE(ii);
	    meta.target_sc_vel_x	= TARGET_SC_VELOCITY_VECTOR(1,ii);
	    meta.target_sc_vel_y	= TARGET_SC_VELOCITY_VECTOR(2,ii);
	    meta.target_sc_vel_z	= TARGET_SC_VELOCITY_VECTOR(3,ii);
	    meta.target_sc_rad_v	= TARGET_SC_RADIAL_VELOCITY(ii);
	    meta.target_sc_tan_v	= TARGET_SC_TANG_VELOCITY(ii);
	    meta.loc_solar_t	= LOCAL_TRUE_SOLAR_TIME(ii);
	    meta.solar_zen		= SOLAR_ZENITH_ANGLE(ii);
	    meta.di_uni_x		= DIPOLE_UNIT_VECTOR(1,ii);
	    meta.di_uni_y		= DIPOLE_UNIT_VECTOR(2,ii);
	    meta.di_uni_z		= DIPOLE_UNIT_VECTOR(3,ii);
	    meta.mono_uni_x		= MONOPOLE_UNIT_VECTOR(1,ii);
	    meta.mono_uni_y		= MONOPOLE_UNIT_VECTOR(2,ii);
	    meta.mono_uni_z		= MONOPOLE_UNIT_VECTOR(3,ii);
    % META
	    MARSIS_postgis_ingest_echo_meta(meta,"marsis_echoes_meta");
    end
    
    if ingest_data
    % DATA
	    MARSIS_rasda_ingest_echo_data_so(data(:,ii:N_echoes:end),orbit_id,meta.echo_id,["MARSIS_" MARSIS_DATA_COLLECTION "_" num2str(orbit_id)]);
    end
    
    if ingest_sim
    % SIM
	    MARSIS_rasda_ingest_echo_data_so( bwimage(:,ii:N_echoes:end),orbit_id,meta.echo_id,["MARSIS_" MARSIS_CSCS_COLLECTION "_" num2str(orbit_id)]);
    end
end
toc








