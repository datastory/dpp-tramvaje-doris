require! fs
require! async

datadir = "#__dirname/../data/DP201207/"
(err, files) <~ fs.readdir datadir
prujezdy = files.filter -> \Den == it.substr 0, 3
# prujezdy.length = 1
output = fs.createWriteStream "#__dirname/../data/processed/usable.csv"
<~ output.write '"Rec_id","Datum","Kod","LnNo","PorNo","EvCislo","Vozovna","FyzAdresa","A","B","C","D","E","F","G","H","Zapsano"'
(err, lines) <~ async.eachSeries prujezdy, (file, cb) ->
    (err, data) <~ fs.readFile "#datadir/#file"
    lines = data.toString!split "\n"
        ..shift! # remove header

    usableLines = lines.filter (line) ->
        return no if line.length == 0
        [rec_id,datum,kod,lnno] = line.split ","
        day = datum.split "/" [1] |> parseInt _, 10
        return no if day in [1 7 8 14 15 21 22 28 29] # weekends
        lnnoInt = parseInt lnno, 10
        return no unless 1 <= lnnoInt <= 29
        return yes
    console.log file
    <~ output.write "\n" + usableLines.join "\n"

    cb!
