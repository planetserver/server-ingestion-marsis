function db_kml_gen(kml_out)

if nargin < 1
	kml_out = "marsis_orbits_footprints.kml";
end

db = "marsisdb";
user = "rasdaman";
table = "marsis_echoes_meta";

[status, output] = system(["psql -U " user " -d " db " -c 'select distinct orbit_id from " table " order by orbit_id'"]);
s = strsplit(output,"\n",1);

orbit_id = zeros(1,length(s)-3);
for ii = 3:(length(s)-1)
	orbit_id(ii-2) = str2num(s{ii});
end

%orbit_id

fhead = fopen ("head.kml","r");
fout = fopen (kml_out,"w");
while (! feof (fhead) )
	text_line = fgetl (fhead);
	fprintf(fout, "%s\n", text_line);
end
#	[outstr, COUNT, ERRMSG] = fscanf (fhead, '%s');
fclose (fhead);
fclose(fout);

outstr = [];
for ii = 1:length(orbit_id)
	orbitstr = orbit_kml_gen(orbit_id(ii));
	outstr = [outstr orbitstr];
end

outstr = [outstr "</Document> \n </kml>"];

fout = fopen (kml_out,"a");
fprintf(fout,"%s",outstr);
fclose(fout);

