require! fs
require! parse: "csv-parse"

minuteBinning = 5_minutes
bins = {}

stream = fs.createReadStream "#__dirname/../data/processed/usable.csv"
reader = parse {delimiter: ','}
stream.pipe reader
i = 0
lastDay = null
output = "zastavka,sloupek,hodina,minuta,zpozdeni"
dump = ->
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
    return if zastavka == "0"
    minute = parseInt minute, 10
    binnedMinute = minuteBinning * Math.floor minute / minuteBinning
    binId = "#zastavka-#sloupek-#hour-#binnedMinute"
    bins[binId] ?= []
    bins[binId].push zpozdeni
<~ reader.on \end
dump!
<~ fs.writeFile "#__dirname/../data/processed/bins-time-day.csv", output
console.log "Done", i
