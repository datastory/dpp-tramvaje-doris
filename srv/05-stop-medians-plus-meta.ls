require! fs
require! parse: "csv-parse"
medians = fs.readFileSync "#__dirname/../data/processed/bins-time-day-median.json" |> JSON.parse
getStops = (cb) ->
    reader = parse {delimiter: ','}, (err, stops) ->
        stops.shift!
        stops .= map ([stop_id,stop_name,stop_lat,stop_lon,location_type,parent_station]) ->
            [zastavka, sloupek] = stop_id.substr 1 .split /[ZN]/
            zastavka = zastavka
            sloupek = sloupek
            lat = parseFloat stop_lat
            lon = parseFloat stop_lon
            {stop_id,stop_name,stop_lat,stop_lon,location_type,parent_station, zastavka, sloupek, lat, lon}
        cb null, stops
    stream = fs.createReadStream "#__dirname/../data/GOOGLE_20120701_20120731/stops.txt"
    stream.pipe reader

(err, stops) <~ getStops

stops_assoc = {}
for stop in stops
    stops_assoc[stop.zastavka] = stop
    stops_assoc["#{stop.zastavka}-#{stop.sloupek}"] = stop


output = []
valid = 0
all = 0
for zastavka, sloupky of medians
    meta = stops_assoc["#zastavka-1"] || stops_assoc[zastavka]
    if meta
        valid++
        output_zastavka = {}
            ..id = meta.parent_station || meta.stop_id
            ..name = meta.stop_name
            ..lat = meta.lat
            ..lon = meta.lon
            ..sloupky = []
        output.push output_zastavka
        values = measurements = 0
        for data, sloupek in sloupky
            continue if data is null
            output_sloupek = {}
                ..id = sloupek
                ..medians = data
            sloupek_meta = stops_assoc["#zastavka-#sloupek"]
            localValues = localMeasurements = 0
            for median in data
                localValues += median if median
                localMeasurements++
            values += localValues
            measurements += localMeasurements
            if sloupek_meta
                output_sloupek
                    ..lat = sloupek_meta.lat
                    ..lon = sloupek_meta.lon
                    ..median_avg = localValues / localMeasurements

            output_zastavka.sloupky.push output_sloupek

        output_zastavka.median_avg = values / measurements

    all++
console.log all, valid
output.sort (a, b) -> b.median_avg - a.median_avg

fs.writeFile "#__dirname/../data/processed/stops-median.json" JSON.stringify output#, 1, 4

