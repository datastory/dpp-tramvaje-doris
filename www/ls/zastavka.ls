container = d3.select 'body' .append \div
    ..attr \class \zastavka
container.append \div
    ..attr \class \closebtn
    ..html "X"
    ..on \click -> container.classed \active no
heading = container.append \h1
lineSelector = container.append \select
    ..attr \class \lineSelector
    ..attr \multiple yes

closeLinesSelector = container.append \button
    ..attr \class 'closeLinesSelector off'
    ..on \click ->
        selectedLinky = []
        d3.selectAll \.multi-group.selected .each -> selectedLinky.push it
        console.log selectedLinky
        window.ig.displayLinky selectedLinky
    ..html "Zobrazit vybrané"

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
        it.time -= it.zpozdeni
        it.fileDay =
            | it.time < 2_hours * 3600 => it.day - 1
            | otherwise                => it.day
        it
    lines = getLnList prujezdy
    if !selectedLineNo
        selectedLineNo := [lines[0].lnno]
    if 'Array' !=typeof! selectedLineNo
        selectedLineNo := [selectedLineNo]
    lineSelector
        ..html ''
        ..selectAll \option .data lines .enter!append \option
            ..html -> "#{it.lnno} (#{it.count} průjezdů)"
            ..attr \value (.lnno)
            ..attr \selected ->
                if it.lnno in selectedLineNo then "selected" else void
        ..on \change ->
            values = for item in @querySelectorAll 'option:checked'
                parseInt item.value, 10
            window.ig.drawZastavka zastavka, sloupek, values
    selectedPrujezdy = prujezdy.filter (.lnno in selectedLineNo)

    prujezdyScatter
        ..html ''
        ..selectAll \div.time .data [0 to 24] .enter!append \div
            ..attr \class \time
            ..style \left -> "#{xScale it * 3600}%"
            ..html -> "#{it}:00"
    prujezdyItems = prujezdyScatter.selectAll \div.group .data selectedPrujezdy .enter!append \div
    if selectedLineNo.length == 1
        closeLinesSelector.classed \off yes
        prujezdyItems
            ..attr \class \group
            ..style \width ->
                "#{xScale timeStart + it.zpozdeni}%"
            ..style \left -> "#{xScale it.time}%"
            ..style \top -> "#{yScale it.day}%"
            ..classed \twominute -> it.zpozdeni > 120
            ..classed \threeminute -> it.zpozdeni > 180
            ..classed \fourminute -> it.zpozdeni > 240
            ..attr \title -> "linka #{it.lnno} pořadí #{it.porno} dne #{it.day}. 7. Zpoždění #{ig.humanZpozdeni it.zpozdeni}, plánovaný příjezd #{humanTime it.time}"
            ..on \click ->
                window.ig.displayLinky [{day: it.fileDay, lnno: it.lnno, porno: it.porno, time: it.time}]
    else
        prujezdyItems
            ..attr \class -> "multi-group mg-#{selectedLineNo.indexOf it.lnno}"
            ..style \left -> "#{xScale it.time + it.zpozdeni}%"
            ..style \top -> "#{yScale it.day}%"
            ..attr \title -> "linka #{it.lnno} pořadí #{it.porno} dne #{it.day}. 7. Zpoždění #{ig.humanZpozdeni it.zpozdeni}, plánovaný příjezd #{humanTime it.time}"
            ..on \click ->
                i = @className.indexOf 'selected'
                if i == -1
                    closeLinesSelector.classed \off off
                    @className += " selected"
                else
                    @className .= substr 0, i


    prujezdyScatter.0.0.scrollLeft = prujezdyScatter.0.0.offsetWidth * 1

ig.humanZpozdeni = ->
    abs = Math.abs it
    sign = if it > 0 then "+" else "-"
    minutes = Math.floor abs / 60
    seconds = abs % 60
    if minutes > 0
        "#{sign}#{minutes}m #{seconds}s"
    else
        "#{sign}#{seconds}s"

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

