function outstr = orbit_kml_gen(orbit_id, db, user, table)

if nargin < 2
	db = "marsisdb";
end

if nargin < 3
	user = "rasdaman";
end

if nargin < 4
table = "marsis_echoes_meta";
end

[status, output] = system(["psql -U " user " -d " db " -c 'SELECT sub_sc_lon, sub_sc_lat from " table " where orbit_id = " num2str(orbit_id) " order by echo_id'"]);
s = strsplit(output,"\n",1);

coord =  zeros(2,length(s)-3);
for ii = 3:(length(s)-1)
	coord(:,ii-2) = sscanf(s{ii},"%f | %f");
	if coord(1,ii-2) > 180
		coord(1,ii-2) = coord(1,ii-2) -360;
	end
end

[status, output] = system(["psql -U " user " -d " db " -c 'SELECT geom_epoch_utc from " table " where orbit_id = " num2str(orbit_id) " order by echo_id'"]);
epochs = strsplit(output,"\n",1);

[status, output] = system(["psql -U " user " -d " db " -c 'SELECT max(echo_id) from " table " where orbit_id = " num2str(orbit_id) "'"]);
se = strsplit(output,"\n",1);
echo_n = str2num(se{3});


outstr = [];
outstr = [outstr "<Placemark>\n <name> " num2str(orbit_id) " </name>\n"];
outstr = [outstr   "<description>\n"];
outstr = [outstr     "<![CDATA[\n"];
outstr = [outstr       "# of echoes: " num2str(echo_n) " </br></br>\n"];
outstr = [outstr       "Time span:</br>\n"];
outstr = [outstr       "From: " epochs{3} " </br>\n"];
outstr = [outstr       "To: " epochs{length(epochs)-1} " </br>\n"];
outstr = [outstr    "]]>\n"];
outstr = [outstr     " </description>\n"];
#outstr = [outstr     " <LookAt>\n"];
#outstr = [outstr     "   <latitude>-18.92</latitude>\n"];
#outstr = [outstr     "   <longitude>-53.985</longitude>\n"];
#outstr = [outstr     "   <altitude>1000000.0</altitude>\n"];
#outstr = [outstr     " </LookAt>\n"];
outstr = [outstr     " <visibility>1</visibility>\n"];
outstr = [outstr     " <open>0</open>\n"];
outstr = [outstr     " <styleUrl>#hightlightStyleMap</styleUrl>\n"];
outstr = [outstr     " <TimeSpan>\n"];
outstr = [outstr     "    <begin>" epochs{3} "</begin>\n"];
outstr = [outstr     "    <end>" epochs{length(epochs)-1} "</end>\n"];
outstr = [outstr     "  </TimeSpan>\n"];
outstr = [outstr     "  <Region>\n"];
outstr = [outstr     "    <LatLonAltBox>\n"];
outstr = [outstr     "      <north>" num2str(max(coord(2,:))) "</north>\n"];
outstr = [outstr     "      <south>" num2str(min(coord(2,:))) "</south>\n"];
outstr = [outstr     "      <east>" num2str(max(coord(1,:))) "</east>\n"];
outstr = [outstr     "      <west>" num2str(min(coord(1,:))) "</west>\n"];
outstr = [outstr     "    </LatLonAltBox>\n"];
outstr = [outstr     "    <Lod>\n"];
outstr = [outstr     "      <minLodPixels>1</minLodPixels>\n"];
outstr = [outstr     "    </Lod>\n"];
outstr = [outstr     "  </Region>\n"];
outstr = [outstr     "  <MultiGeometry>\n"];
#outstr = [outstr     "    <Point>\n"];
#outstr = [outstr     "      <coordinates>\n"];
#outstr = [outstr     "      -53.985,-18.92,100\n"];
#outstr = [outstr     "      </coordinates>\n"];
#outstr = [outstr     "    </Point>\n"];
outstr = [outstr     "    <LineString>\n"];
outstr = [outstr     "      <extrude>0</extrude>\n"];
outstr = [outstr     "      <tessellate>1</tessellate>\n"];
outstr = [outstr     "      <altitudeMode>clampToGround</altitudeMode>\n"];
outstr = [outstr     "      <coordinates>\n"];
outstr = [outstr "      " num2str(coord(1,1)) ", " num2str(coord(2,1)) ", 100\n"];
prev = 1;
for ii = 2:20:(length(coord)-1)
	if coord(1,ii)*coord(1,prev)<0
		outstr = [outstr     "      </coordinates>\n"];
		outstr = [outstr     "    </LineString>\n"];
		outstr = [outstr     "    <LineString>\n"];
		outstr = [outstr     "      <extrude>0</extrude>\n"];
		outstr = [outstr     "      <tessellate>1</tessellate>\n"];
		outstr = [outstr     "      <altitudeMode>clampToGround</altitudeMode>\n"];
		outstr = [outstr     "      <coordinates>\n"];
	end
	prev = ii;
	outstr = [outstr  "      " num2str(coord(1,ii)) ", " num2str(coord(2,ii)) ", 100\n"];
end
if coord(1,prev)*coord(1,length(coord))<0
		outstr = [outstr     "      </coordinates>\n"];
		outstr = [outstr     "    </LineString>\n"];
		outstr = [outstr     "    <LineString>\n"];
		outstr = [outstr     "      <extrude>0</extrude>\n"];
		outstr = [outstr     "      <tessellate>1</tessellate>\n"];
		outstr = [outstr     "      <altitudeMode>clampToGround</altitudeMode>\n"];
		outstr = [outstr     "      <coordinates>\n"];
end
outstr = [outstr  "      " num2str(coord(1,length(coord))) ", " num2str(coord(2,length(coord))) ", 100\n"];
outstr = [outstr     "      </coordinates>\n"];
outstr = [outstr     "    </LineString>\n"];
outstr = [outstr     "  </MultiGeometry>\n"];
outstr = [outstr     "</Placemark>\n"];

