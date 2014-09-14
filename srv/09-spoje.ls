require! fs
require! async
require! parse: "csv-parse"

stream = fs.createReadStream "#__dirname/../data/processed/usable.csv"
# stream = fs.createReadStream "#__dirname/../data/DP201207/Den02.csv"
reader = parse {delimiter: ','}
stream.pipe reader
i = 0
lastDay = null
headers = ["zastavka" "sloupek" "time" "zpozdeni" "kod"]
records_linky = {}
lastLn = null
types = {}
save = (id) ->
    records = records_linky[id]
        ..saved = true
    day = records.fileDay
    csv = (([headers] ++ records).map (.join ',')).join '\n'
    fs.writeFile "#__dirname/../data/processed/spoje/#day-#id.csv", csv
reader.on \data (line) ->
    [rec_id, datum, kod, lnno, porno, evcislo, vozovna, fyzadresa, zastavka, sloupek, zpozdeni] = line
    return if rec_id == "Rec_id"
    [date, time] = datum.split ' '
    [month, day, year] = date.split "/"
    fileDay = day = parseInt day, 10
    [h, m, s] = time.split ":"
    h = parseInt h, 10
    m = parseInt m, 10
    s = parseInt s, 10
    if h < 3
        fileDay--
    id = "#lnno-#porno"
    if !records_linky[id] or records_linky[id].fileDay != fileDay
        save id if records_linky[id]
        records_linky[id] = []
    records = records_linky[id]
        ..fileDay = fileDay
        ..saved = false
    lastLn = lnno
    v = h * 60 * 60 + m * 60 + s
    records.push [zastavka, sloupek, v, zpozdeni, kod]

<~ reader.on \end
for id, records of records_linky
    if !records.saved
        save id

# console.log "Done", i
