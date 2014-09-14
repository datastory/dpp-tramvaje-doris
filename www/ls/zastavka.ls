container = d3.select 'body' .append \div
    ..attr \class \zastavka
container.append \div
    ..attr \class \closebtn
    ..html "X"
    ..on \click -> container.classed \active no
heading = container.append \h1
lineSelector = container.append \select
    ..attr \class \lineSelector

prujezdyScatter = container.append \div
    ..attr \class \prujezdyScatter

timeStart = 0
xScale = d3.scale.linear!
    ..domain [timeStart, 4*3600]
    ..range [0 100]
yScale = d3.scale.linear!
    ..domain [1 31]
    ..range [2 96]

prujezdyDayLegend = container.append \div
    ..attr \class \prujezdyDayLegend
    ..selectAll \div .data [1 to 31] .enter!append \div
        ..attr \class \day
        ..style \top -> "#{yScale it}%"
        ..html -> it
window.ig.drawZastavka = (zastavka, sloupek, selectedLineNo) ->
    container.classed \active yes
    heading.html zastavka.name
    [zastavkaId] = zastavka.id.slice 1 .split /[NZ]/
    sloupek ?= zastavka.sloupky[0]
    (err, prujezdy) <~ d3.csv "../data/processed/sloupky/#zastavkaId-#{sloupek.id}.csv", ->
        for field in <[time day lnno porno zpozdeni]>
            it[field] = parseInt it[field], 10
        it.fileDay =
            | it.time < 2_hours * 3600 => it.day - 1
            | otherwise                => it.day
        it
    prujezdy.length
    lines = getLnList prujezdy
    if !selectedLineNo
        selectedLineNo := lines[0].lnno
    lineSelector
        ..html ''
        ..selectAll \option .data lines .enter!append \option
            ..html -> "#{it.lnno} (#{it.count} průjezdů)"
            ..attr \value (.lnno)
            ..attr \selected ->
                if selectedLineNo == it.lnno then "selected" else void
        ..on \change ->
            lnno = parseInt @value, 10
            window.ig.drawZastavka zastavka, sloupek, lnno
    selectedPrujezdy = prujezdy.filter (.lnno == selectedLineNo)
    prujezdyScatter
        ..html ''
        ..selectAll \div.time .data [0 to 24] .enter!append \div
            ..attr \class \time
            ..style \left -> "#{xScale it * 3600}%"
            ..html -> "#{it}:00"
        ..selectAll \div.group .data selectedPrujezdy .enter!append \div
            ..attr \class \group
            ..style \width ->
                "#{xScale timeStart + it.zpozdeni}%"
            ..style \left -> "#{xScale it.time - it.zpozdeni}%"
            ..style \top -> "#{yScale it.day}%"
            ..classed \twominute -> it.zpozdeni > 120
            ..classed \threeminute -> it.zpozdeni > 180
            ..classed \fourminute -> it.zpozdeni > 240
            ..attr \title -> "linka #{it.lnno} pořadí #{it.porno} dne #{it.day}. 7. Zpoždění #{ig.humanZpozdeni it.zpozdeni}, plánovaný příjezd #{humanTime it.time}"
            ..on \click ->
                console.log it.fileDay, it.lnno, it.porno, it.time
                window.ig.displayLinka it.fileDay, it.lnno, it.porno, it.time
        ..0.0.scrollLeft = prujezdyScatter.0.0.offsetWidth * 1

ig.humanZpozdeni = ->
    minutes = Math.floor it / 60
    seconds = it % 60
    if minutes > 0
        "#{minutes}m #{seconds}s"
    else
        "#{seconds}s"

ig.humanTime = humanTime = ->
    hours = Math.floor it / 3600
    minutes = Math.floor (it % 3600) / 60
    seconds = it % 60
    hours = "0#hours" if hours < 10
    minutes = "0#minutes" if minutes < 10
    seconds = "0#seconds" if seconds < 10

    "#hours:#minutes:#seconds"

getLnList = ->
    lines_assoc = {}
    for {lnno} in it
        lines_assoc[lnno] = lines_assoc[lnno] + 1 || 1
    out = for lnno, count of lines_assoc
        lnno = parseInt lnno, 10
        {lnno, count}
    out.sort (a, b) -> b.count - a.count
    out

