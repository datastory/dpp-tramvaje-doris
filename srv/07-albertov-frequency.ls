require! fs
require! parse: "csv-parse"

stream = fs.createReadStream "#__dirname/../data/processed/usable.csv"
# stream = fs.createReadStream "#__dirname/../data/DP201207/Den02.csv"
reader = parse {delimiter: ','}
stream.pipe reader
i = 0
lastDay = null
headers = ["time", "day", "lnno"]
records = []
lastLn = null
types = {}
reader.on \data (line) ->
    [rec_id, datum, kod, lnno, porno, evcislo, vozovna, fyzadresa, zastavka, sloupek, zpozdeni] = line
    return unless lnno in <[18 24]>
    return if zastavka != '876'
    return if sloupek != '1'
    types[kod] = (types[kod] + 1) || 1
    return unless kod == "M "
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
    v /= 3600
    records.push [v, day, lnno]

<~ reader.on \end
console.log types
<~ fs.writeFile "#__dirname/../data/processed/albertov.csv", (([headers] ++ records).map (.join ',')).join '\n'
console.log "Done", i
