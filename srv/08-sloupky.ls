require! fs
require! async
require! parse: "csv-parse"

stream = fs.createReadStream "#__dirname/../data/processed/usable.csv"
# stream = fs.createReadStream "#__dirname/../data/DP201207/Den02.csv"
reader = parse {delimiter: ','}
stream.pipe reader
i = 0
lastDay = null
headers = ["time" "day" "lnno" "porno" "zpozdeni", "kod"]
records_sloupek = {}
lastLn = null
types = {}
reader.on \data (line) ->
    [rec_id, datum, kod, lnno, porno, evcislo, vozovna, fyzadresa, zastavka, sloupek, zpozdeni] = line
    return if rec_id == "Rec_id"
    id = "#zastavka-#sloupek"
    # return if zastavka != '876'
    # return if sloupek != '1'
    records_sloupek[id] ?= []
    records = records_sloupek[id]
    types[kod] = (types[kod] + 1) || 1
    # return unless kod == "M "
    [date, time] = datum.split ' '
    [month, day, year] = date.split "/"
    day = parseInt day, 10
    [h, m, s] = time.split ":"
    h = parseInt h, 10
    m = parseInt m, 10
    s = parseInt s, 10
    # return if h < 7
    # return if h > 20
    # return if lnno = lastLn
    lastLn = lnno
    v = h * 60 * 60 + m * 60 + s
    # v /= 3600
    records.push [v, day, lnno, porno, zpozdeni, kod]

<~ reader.on \end
console.log types
tasks = for id, records of records_sloupek
    {id, records}

async.eachLimit tasks, 20, ({id, records}, cb) ->
    (err) <~ fs.writeFile "#__dirname/../data/processed/sloupky/#id.csv", (([headers] ++ records).map (.join ',')).join '\n'
    console.log err if err
    cb!

# console.log "Done", i
