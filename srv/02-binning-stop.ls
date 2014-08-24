require! fs
require! parse: "csv-parse"

minuteBinning = 5_minutes
bins = {}

stream = fs.createReadStream "#__dirname/../data/processed/usable.csv"
reader = parse {delimiter: ','}
stream.pipe reader
i = 0
lastDay = null
output = "zastavka,sloupek,den,hodina,minuta,zpozdeni"
dump = (day) ->
    dailyOutput = for binId, value of bins
        (binId.split "-") ++ [value.join ';']
    output += "\n" + dailyOutput.join "\n"
    bins := {}
reader.on \data (line) ->
    [rec_id, datum, kod, lnno, porno, evcislo, vozovna, fyzadresa, zastavka, sloupek, zpozdeni] = line
    return if datum == "Datum" # first line
    i++
    unless i % 100000
        console.log i
    [month, day, year, hour, minute, second] = datum.split /[ :\/]/
    if lastDay != day
        dump day if lastDay != null
        lastDay := day
    minute = parseInt minute, 10
    binnedMinute = minuteBinning * Math.floor minute / minuteBinning
    binId = "#zastavka-#sloupek-#day-#hour-#binnedMinute"
    bins[binId] ?= []
    bins[binId].push zpozdeni
<~ reader.on \end
dump lastDay
<~ fs.writeFile "#__dirname/../data/processed/bins-time.csv", output
console.log "Done", i
