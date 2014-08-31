require! fs
require! async

datadir = "#__dirname/../data/DP201207/"
(err, files) <~ fs.readdir datadir
prujezdy = files.filter -> \Den == it.substr 0, 3

# prujezdy .= slice 1, 2

output = fs.createWriteStream "#__dirname/../data/processed/delayed.csv"
tooBig = 0
bigEnough = 0
previousStops = {}
<~ output.write 'lnno,porno,delay,a,b,c,d,e,f,g'
(err, lines) <~ async.eachSeries prujezdy, (file, cb) ->
    linky = {}
    (err, data) <~ fs.readFile "#datadir/#file"
    lines = data.toString!split "\n"
        ..shift! # remove header
    outputString = ""
    for line in lines
        [_,datum,kod,lnno,porno,_,_,_,zastavka,sloupek,zpozdeni] = line.split ","
        continue if not datum
        day = datum.split "/" [1] |> parseInt _, 10
        continue if day in [1 7 8 14 15 21 22 28 29] # weekends
        lnnoInt = parseInt lnno, 10
        continue unless 1 <= lnnoInt <= 29
        zpozdeniInt = parseInt zpozdeni, 10
        continue if isNaN zpozdeniInt
        continue unless kod[1] == \M
        zastavkaInt = parseInt zastavka, 10
        continue unless zastavkaInt
        id = "#lnno-#porno"
        continue if previousStops[id] == zastavkaInt
        previousStops[id] = zastavkaInt
        linky[id] ?= []
        linky[id].unshift zpozdeniInt
        if linky[id].length >= 8
            latestZpozdeni = linky[id].slice!
            latestZpozdeni.length = 8
            if latestZpozdeni.some (-> not (-900 < it < 900))
                ++tooBig
                continue
            else
                ++bigEnough

            outLine = [lnno,porno] ++ latestZpozdeni
            outputString += "\n" + outLine.join ","
    <~ output.write outputString
    cb!

console.log tooBig, bigEnough
