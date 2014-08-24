require! fs
require! parse: "csv-parse"

minuteBinning = 5_minutes
hoursInDay = 24_hours
binsInHour = 60_minutes / minuteBinning

dailyArrayLength = hoursInDay * binsInHour

bins = {}

stream = fs.createReadStream "#__dirname/../data/processed/bins-time-day.csv"
reader = parse {delimiter: ','}
stream.pipe reader

i = 0

reader.on \data (line) ->
    [zastavka,sloupek,hodina,minuta,zpozdeni] = line
    return if zastavka == "zastavka" # first line
    i++
    hodina = parseInt hodina, 10
    minuta = parseInt minuta, 10
    sloupek = parseInt sloupek, 10
    unless i % 10000
        console.log i
    zpozdeni = zpozdeni.split ";"
        .map (parseInt _, 10)
        .sort!
    return if zpozdeni.length < 5
    median = zpozdeni[Math.round zpozdeni.length / 2]
    return if isNaN median

    bins[zastavka] ?= []
    bins[zastavka][sloupek] ?= new Array dailyArrayLength

    arrayPosition = hodina * binsInHour + minuta / minuteBinning

    bins[zastavka][sloupek][arrayPosition] = median

<~ reader.on \end

<~ fs.writeFile do
    "#__dirname/../data/processed/bins-time-day-median.json"
    JSON.stringify bins

